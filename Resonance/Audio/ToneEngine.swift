import AVFoundation
import Combine
import MediaPlayer

/// An optional ambient bed mixed under the meditation tone. All four are
/// synthesized in real time — no audio files. The DSP mirrors a validated
/// offline reference: rain is a pink-noise patter bed plus stochastic
/// droplet ticks, ocean is irregular swells crossfading deep rumble with a
/// bright foaming wash, wind is a gusting random walk driving both loudness
/// and a resonant whoosh, fire is a flickering rumble with sparse snappy
/// crackles and occasional pops.
enum AmbientSound: String, CaseIterable, Identifiable {
    case off = "Off"
    case rain = "Rain"
    case ocean = "Ocean"
    case wind = "Wind"
    case fire = "Fire"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .off: "speaker.slash.fill"
        case .rain: "cloud.rain.fill"
        case .ocean: "water.waves"
        case .wind: "wind"
        case .fire: "flame.fill"
        }
    }
}

/// Generates meditation tones in real time with `AVAudioEngine`. For
/// binaural modes the left ear gets the carrier frequency and the right ear
/// gets carrier + beat; the brain perceives the difference as a slow pulse.
///
/// Every level change is a timed linear ramp (so a fade asked to take six
/// seconds takes six seconds regardless of the starting level), and the
/// ambient output passes through a tanh soft limiter so the loudest rain
/// tick rounds off gently instead of clipping.
final class ToneEngine: ObservableObject {
    @Published private(set) var isPlaying = false

    var volume: Double = 0.6 {
        didSet { retarget(seconds: 0.3) }
    }

    var ambient: AmbientSound = .off {
        didSet {
            ambientKind = Self.kindIndex(of: ambient)
            retarget(seconds: 1.2)
        }
    }

    var ambientVolume: Double = 0.5 {
        didSet { retarget(seconds: 0.3) }
    }

    /// Pure sine tones sound far louder than music at the same level.
    private static let headroom = 0.25
    private static let ambientHeadroom = 0.16

    /// Voice ducking: while a guiding voice speaks (Journey of Souls), the
    /// tone and bed dip to this fraction so words stay clear.
    private var duckMultiplier = 1.0

    /// Dips the tone + ambient bed under a speaking voice, or restores them.
    func setDucked(_ ducked: Bool) {
        duckMultiplier = ducked ? 0.4 : 1.0
        retarget(seconds: 0.4)
    }

    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private let sampleRate: Double = 44_100
    private var remoteCommandTargets: [(MPRemoteCommand, Any)] = []
    private var fadingOut = false

    // State below is read by the audio render thread. Frequencies are only
    // written before the engine starts; amplitudes move via timed ramps.
    private var leftHz: Double = 200
    private var rightHz: Double = 206
    private var leftPhase: Double = 0
    private var rightPhase: Double = 0
    private var amplitude = 0.0
    private var targetAmplitude = 0.0
    private var toneRamp = 1e-5
    /// Equal-loudness compensation: higher carriers (like the 528 Hz pure
    /// tone) are perceived far louder than the low binaural carriers at the
    /// same level, so they get scaled down to match.
    private var toneScale = 1.0
    private var pureTone = false
    private var ambientAmp = 0.0
    private var ambientTarget = 0.0
    private var ambientRamp = 1e-5

    // Ambient synthesis state (one generator per channel for stereo width).
    private var ambientKind = 0 // 0 off · 1 rain · 2 ocean · 3 wind
    private var clock = 0.0
    private var noiseSeed: [UInt32] = [0x1234_5678, 0x9ABC_DEF1]
    // pink noise (Paul Kellet economy filter)
    private var pinkB0 = [0.0, 0.0]
    private var pinkB1 = [0.0, 0.0]
    private var pinkB2 = [0.0, 0.0]
    // rain
    private var rainHP = [0.0, 0.0]
    private var rainBedLP = [0.0, 0.0]
    private var dropEnv = [0.0, 0.0]
    private var dropDecay = [0.0, 0.0]
    private var dropK = [0.3, 0.3]
    private var dropLP = [0.0, 0.0]
    private var rainWalk = [0.0, 0.0]
    private var rainWalkTarget = [0.0, 0.0]
    // ocean
    private var brown = [0.0, 0.0]
    private var deepLP = [0.0, 0.0]
    private var oceanHP = [0.0, 0.0]
    private var washLP = [0.0, 0.0]
    private var oceanWalk = [0.0, 0.0]
    private var oceanWalkTarget = [0.0, 0.0]
    // wind
    private var windRumLP = [0.0, 0.0]
    private var svLow = [0.0, 0.0]
    private var svBand = [0.0, 0.0]
    private var windWalk = [0.0, 0.0]
    private var windWalkTarget = [0.0, 0.0]
    // fire
    private var fireRumLP = [0.0, 0.0]
    private var fireWalk = [0.0, 0.0]
    private var fireWalkTarget = [0.0, 0.0]
    private var crackEnv = [0.0, 0.0]
    private var crackDecay = [0.0, 0.0]
    private var crackK = [0.6, 0.6]
    private var crackLP = [0.0, 0.0]

    init() {
        registerRemoteCommands()
        registerAudioSessionObservers()
    }

    func start(mode: MeditationMode) {
        start(
            carrierHz: mode.carrierHz,
            beatHz: mode.beatHz,
            pureTone: mode.isPureTone,
            title: mode.name,
            subtitle: "Resonance · \(mode.bandLabel)"
        )
    }

    /// Lower-level entry used by both the frequency modes and the Journey of
    /// Souls bed, so the engine, fades, lock-screen and interruption logic
    /// are shared rather than duplicated.
    func start(
        carrierHz: Double,
        beatHz: Double,
        pureTone isPure: Bool,
        title: String,
        subtitle: String
    ) {
        teardown()

        leftHz = carrierHz
        rightHz = carrierHz + beatHz
        toneScale = min(1.0, pow(200.0 / carrierHz, 0.6))
        pureTone = isPure
        duckMultiplier = 1.0
        leftPhase = 0
        rightPhase = 0
        amplitude = 0
        ambientAmp = 0
        clock = 0
        fadingOut = false
        resetAmbientState()

        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        let node = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self else { return noErr }
            let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let twoPi = 2.0 * Double.pi
            let leftStep = twoPi * self.leftHz / self.sampleRate
            let rightStep = twoPi * self.rightHz / self.sampleRate

            for frame in 0..<Int(frameCount) {
                self.amplitude = Self.step(self.amplitude, toward: self.targetAmplitude, by: self.toneRamp)
                self.ambientAmp = Self.step(self.ambientAmp, toward: self.ambientTarget, by: self.ambientRamp)
                self.clock += 1.0 / self.sampleRate

                var toneAmp = self.amplitude
                if self.pureTone {
                    // A barely-there slow shimmer keeps a long pure tone
                    // from feeling like a static laser on the ear.
                    toneAmp *= 0.92 + 0.08 * sin(2.0 * .pi * 0.08 * self.clock)
                }
                var left = sin(self.leftPhase) * toneAmp
                var right = sin(self.rightPhase) * toneAmp
                self.leftPhase += leftStep
                if self.leftPhase > twoPi { self.leftPhase -= twoPi }
                self.rightPhase += rightStep
                if self.rightPhase > twoPi { self.rightPhase -= twoPi }

                if self.ambientAmp > 0.0001 {
                    left += self.ambientSample(channel: 0) * self.ambientAmp
                    right += self.ambientSample(channel: 1) * self.ambientAmp
                }

                for (channel, buffer) in buffers.enumerated() {
                    let samples = UnsafeMutableBufferPointer<Float>(buffer)
                    let value = channel == 0 ? left : right
                    samples[frame] = Float(max(-1.0, min(1.0, value)))
                }
            }
            return noErr
        }

        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        sourceNode = node

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
            isPlaying = true
            retarget(seconds: 3.0) // luxurious fade-in to open the session
            publishNowPlaying(title: title, subtitle: subtitle)
        } catch {
            print("ToneEngine failed to start: \(error)")
        }
    }

    func setPaused(_ paused: Bool) {
        guard sourceNode != nil else { return }
        fadingOut = false
        isPlaying = !paused
        // Resuming after a phone call or another app played audio leaves our
        // session deactivated and the engine stopped — bring both back before
        // ramping the level up, or "Resume" would move a target on dead audio.
        if !paused {
            reactivateSession()
        }
        retarget(seconds: 1.5)
        updateNowPlayingRate()
    }

    /// Reactivates the audio session and restarts the engine if an
    /// interruption (call, Siri, another app's audio) left them down.
    private func reactivateSession() {
        guard sourceNode != nil else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            if !engine.isRunning {
                try engine.start()
            }
        } catch {
            print("ToneEngine failed to reactivate: \(error)")
        }
    }

    /// Fades out over ~1 s, then releases the audio engine.
    func stop() {
        guard sourceNode != nil else { return }
        fadingOut = false
        isPlaying = false
        retarget(seconds: 1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { [weak self] in
            guard let self, !self.isPlaying else { return }
            self.teardown()
        }
    }

    /// Long musical fade for a session's natural ending: the sound drifts
    /// down to silence over `seconds`, then the engine is released.
    func fadeOutAndStop(over seconds: Double) {
        guard sourceNode != nil else { return }
        fadingOut = true
        setTargets(tone: 0, ambient: 0, seconds: seconds)
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds + 0.4) { [weak self] in
            guard let self, self.fadingOut else { return }
            self.fadingOut = false
            self.isPlaying = false
            self.teardown()
        }
    }

    /// Restores normal levels if the user extends the session mid-fade.
    func cancelFadeOut() {
        guard fadingOut else { return }
        fadingOut = false
        retarget(seconds: 1.0)
    }

    private func retarget(seconds: Double) {
        guard sourceNode != nil, !fadingOut else { return }
        let tone = isPlaying ? volume * Self.headroom * toneScale * duckMultiplier : 0
        let bed = (isPlaying && ambient != .off) ? ambientVolume * Self.ambientHeadroom * duckMultiplier : 0
        setTargets(tone: tone, ambient: bed, seconds: seconds)
    }

    /// Timed ramps: the step size is derived from the distance to travel,
    /// so the transition takes `seconds` regardless of the current level.
    private func setTargets(tone: Double, ambient bed: Double, seconds: Double) {
        let span = sampleRate * max(seconds, 0.05)
        toneRamp = max(abs(tone - amplitude) / span, 1e-9)
        ambientRamp = max(abs(bed - ambientAmp) / span, 1e-9)
        targetAmplitude = tone
        ambientTarget = bed
    }

    private func teardown() {
        if let node = sourceNode {
            engine.stop()
            engine.detach(node)
            sourceNode = nil
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        }
        amplitude = 0
        targetAmplitude = 0
        ambientAmp = 0
        ambientTarget = 0
    }

    private func resetAmbientState() {
        pinkB0 = [0, 0]; pinkB1 = [0, 0]; pinkB2 = [0, 0]
        rainHP = [0, 0]; rainBedLP = [0, 0]
        dropEnv = [0, 0]; dropDecay = [0, 0]; dropK = [0.3, 0.3]; dropLP = [0, 0]
        rainWalk = [0, 0]; rainWalkTarget = [0, 0]
        brown = [0, 0]; deepLP = [0, 0]; oceanHP = [0, 0]; washLP = [0, 0]
        oceanWalk = [0, 0]; oceanWalkTarget = [0, 0]
        windRumLP = [0, 0]; svLow = [0, 0]; svBand = [0, 0]
        windWalk = [0, 0]; windWalkTarget = [0, 0]
        fireRumLP = [0, 0]; fireWalk = [0, 0]; fireWalkTarget = [0, 0]
        crackEnv = [0, 0]; crackDecay = [0, 0]; crackK = [0.6, 0.6]; crackLP = [0, 0]
    }

    // MARK: - Ambient synthesis (render thread)

    private static func step(_ value: Double, toward target: Double, by ramp: Double) -> Double {
        if value < target { return min(value + ramp, target) }
        if value > target { return max(value - ramp, target) }
        return value
    }

    private static func kindIndex(of sound: AmbientSound) -> Int {
        switch sound {
        case .off: 0
        case .rain: 1
        case .ocean: 2
        case .wind: 3
        case .fire: 4
        }
    }

    private func white(_ ch: Int) -> Double {
        var s = noiseSeed[ch]
        s ^= s << 13
        s ^= s >> 17
        s ^= s << 5
        noiseSeed[ch] = s
        return Double(s) / Double(UInt32.max) * 2.0 - 1.0
    }

    private func u01(_ ch: Int) -> Double {
        (white(ch) + 1.0) * 0.5
    }

    private func pink(_ ch: Int) -> Double {
        let w = white(ch)
        pinkB0[ch] = 0.99765 * pinkB0[ch] + w * 0.0990460
        pinkB1[ch] = 0.96300 * pinkB1[ch] + w * 0.2965164
        pinkB2[ch] = 0.57000 * pinkB2[ch] + w * 1.0526913
        return (pinkB0[ch] + pinkB1[ch] + pinkB2[ch] + w * 0.1848) * 0.18
    }

    /// Smoothed random-walk LFO in [-1, 1] — nature never repeats exactly.
    private func walk(
        _ value: inout Double, _ target: inout Double,
        ch: Int, rateHz: Double, smoothSeconds: Double
    ) {
        if u01(ch) < rateHz / sampleRate {
            target = white(ch)
        }
        value += (target - value) / (sampleRate * smoothSeconds)
    }

    private func rainSample(_ ch: Int) -> Double {
        // patter bed: pink noise band-limited to ~200 Hz – 5 kHz
        let p = pink(ch)
        rainHP[ch] += 0.028 * (p - rainHP[ch])
        let bedHP = p - rainHP[ch]
        rainBedLP[ch] += 0.51 * (bedHP - rainBedLP[ch])
        let bed = rainBedLP[ch]

        // droplet ticks: ~45/s per ear, each a 2–8 ms enveloped burst with
        // random brightness — small drops bright, big drops duller
        if u01(ch) < 45.0 / sampleRate {
            let amp = u01(ch)
            dropEnv[ch] = 0.25 + 0.75 * amp * amp
            let tau = 0.002 + 0.006 * u01(ch)
            dropDecay[ch] = exp(-1.0 / (sampleRate * tau))
            dropK[ch] = 0.18 + 0.5 * u01(ch)
        }
        dropEnv[ch] *= dropDecay[ch]
        dropLP[ch] += dropK[ch] * (white(ch) - dropLP[ch])
        let drop = dropLP[ch] * dropEnv[ch] * 1.4

        // the whole shower gently waxes and wanes
        walk(&rainWalk[ch], &rainWalkTarget[ch], ch: ch, rateHz: 1.0 / 1.5, smoothSeconds: 0.7)
        return (bed * 0.9 + drop) * (1.0 + 0.25 * rainWalk[ch]) * 0.75
    }

    private func oceanSample(_ ch: Int) -> Double {
        // irregular swell: two incommensurate slow sines + a random drift,
        // so no two waves are ever identical
        walk(&oceanWalk[ch], &oceanWalkTarget[ch], ch: ch, rateHz: 0.25, smoothSeconds: 2.0)
        let phase = ch == 0 ? 0.0 : 0.35
        let m = 0.45 * sin(2.0 * .pi * 0.043 * clock + phase)
            + 0.35 * sin(2.0 * .pi * 0.071 * clock + 1.7 + phase)
            + 0.35 * oceanWalk[ch]
        let env = min(max((m + 1.0) * 0.5, 0.0), 1.0)
        let crash = pow(env, 2.4)

        // deep layer: the rumbling body of the sea
        brown[ch] = (brown[ch] + 0.024 * white(ch)) * 0.997
        deepLP[ch] += 0.055 * (brown[ch] * 1.4 - deepLP[ch])

        // bright layer: the foaming wash that swells with each crash
        let p = pink(ch)
        oceanHP[ch] += 0.069 * (p - oceanHP[ch])
        washLP[ch] += 0.434 * ((p - oceanHP[ch]) - washLP[ch])

        let level = 0.30 + 0.70 * crash
        return level * (deepLP[ch] * 0.95 + washLP[ch] * (0.25 + 1.7 * crash)) * 1.15
    }

    private func windSample(_ ch: Int) -> Double {
        walk(&windWalk[ch], &windWalkTarget[ch], ch: ch, rateHz: 1.0 / 3.0, smoothSeconds: 1.2)
        let gust = min(max(0.5 + 0.5 * windWalk[ch], 0.0), 1.0)
        let g = 0.15 + 0.85 * pow(gust, 1.5)

        // rumble bed
        brown[ch] = (brown[ch] + 0.024 * white(ch)) * 0.997
        windRumLP[ch] += 0.035 * (brown[ch] * 1.5 - windRumLP[ch])

        // whoosh: resonant bandpass whose center rises with the gust
        let fc = 240.0 + 650.0 * gust
        let f1 = 2.0 * sin(.pi * fc / sampleRate)
        let w = white(ch)
        svLow[ch] += f1 * svBand[ch]
        let svHigh = w - svLow[ch] - 0.7 * svBand[ch]
        svBand[ch] += f1 * svHigh

        return (windRumLP[ch] * 0.55 + svBand[ch]) * g * 1.5
    }

    private func fireSample(_ ch: Int) -> Double {
        // flame flicker: a faster random walk than wind's gusts
        walk(&fireWalk[ch], &fireWalkTarget[ch], ch: ch, rateHz: 2.0, smoothSeconds: 0.25)
        let flick = 0.65 + 0.35 * (0.5 + 0.5 * fireWalk[ch])

        // fire body: deep flickering rumble
        brown[ch] = (brown[ch] + 0.024 * white(ch)) * 0.997
        fireRumLP[ch] += 0.020 * (brown[ch] * 1.3 - fireRumLP[ch])

        // soft flame hiss
        let hiss = pink(ch) * 0.10

        // crackles: ~12/s, very snappy (0.8–3.8 ms), amplitude heavily
        // skewed so most are tiny ticks and the occasional one really pops
        if u01(ch) < 12.0 / sampleRate {
            let a = u01(ch)
            crackEnv[ch] = 0.15 + 0.85 * a * a * a
            let tau = 0.0008 + 0.003 * u01(ch)
            crackDecay[ch] = exp(-1.0 / (sampleRate * tau))
            crackK[ch] = 0.5 + 0.45 * u01(ch)
        }
        crackEnv[ch] *= crackDecay[ch]
        crackLP[ch] += crackK[ch] * (white(ch) - crackLP[ch])
        let crack = crackLP[ch] * crackEnv[ch] * 1.9

        return (fireRumLP[ch] * 0.55 * flick + hiss * flick + crack) * 1.1
    }

    private func ambientSample(channel ch: Int) -> Double {
        let raw: Double = switch ambientKind {
        case 1: rainSample(ch)
        case 2: oceanSample(ch)
        case 3: windSample(ch)
        case 4: fireSample(ch)
        default: 0
        }
        // soft limiter: transparent at normal levels, rounds the loudest
        // droplet tick instead of clipping it
        return tanh(raw)
    }

    // MARK: - Lock screen integration

    private func publishNowPlaying(title: String, subtitle: String) {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtist: subtitle,
            MPNowPlayingInfoPropertyIsLiveStream: true,
            MPNowPlayingInfoPropertyPlaybackRate: 1.0,
        ]
    }

    private func updateNowPlayingRate() {
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    // MARK: - Interruption handling

    /// True while an interruption (call, Siri, another app) has us paused,
    /// so we know whether to auto-resume — but only if the user hadn't
    /// already paused on purpose.
    private var interruptedWhilePlaying = false

    private func registerAudioSessionObservers() {
        let center = NotificationCenter.default
        center.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        // If the media server resets, the engine graph is invalid — rebuild
        // it on next resume.
        center.addObserver(
            self,
            selector: #selector(handleMediaReset),
            name: AVAudioSession.mediaServicesWereResetNotification,
            object: nil
        )
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let raw = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }

        switch type {
        case .began:
            // The system has already ducked us to silence; mirror that in
            // our own state so the UI shows "paused" and remember to resume.
            if isPlaying {
                interruptedWhilePlaying = true
                isPlaying = false
                retarget(seconds: 0.2)
                updateNowPlayingRate()
            }
        case .ended:
            guard interruptedWhilePlaying else { return }
            interruptedWhilePlaying = false
            let shouldResume = (info[AVAudioSessionInterruptionOptionKey] as? UInt)
                .map { AVAudioSession.InterruptionOptions(rawValue: $0).contains(.shouldResume) } ?? true
            if shouldResume {
                setPaused(false)
            }
        @unknown default:
            break
        }
    }

    @objc private func handleMediaReset() {
        // Force a fresh session + engine start on the next resume.
        interruptedWhilePlaying = isPlaying
    }

    private func registerRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        let bindings: [(MPRemoteCommand, (ToneEngine) -> Void)] = [
            (center.playCommand, { $0.setPaused(false) }),
            (center.pauseCommand, { $0.setPaused(true) }),
            (center.togglePlayPauseCommand, { $0.setPaused($0.isPlaying) }),
        ]
        for (command, action) in bindings {
            let target = command.addTarget { [weak self] _ in
                guard let self, self.sourceNode != nil else { return .commandFailed }
                action(self)
                return .success
            }
            remoteCommandTargets.append((command, target))
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        for (command, target) in remoteCommandTargets {
            command.removeTarget(target)
        }
        engine.stop()
    }
}
