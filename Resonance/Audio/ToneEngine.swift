import AVFoundation
import Combine
import MediaPlayer

/// An optional ambient bed mixed under the meditation tone. All three are
/// synthesized in real time as shaped noise — no audio files:
/// rain is low-passed white noise, ocean is brown noise with a slow swell,
/// wind is brown-ish noise whose brightness drifts.
enum AmbientSound: String, CaseIterable, Identifiable {
    case off = "Off"
    case rain = "Rain"
    case ocean = "Ocean"
    case wind = "Wind"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .off: "speaker.slash.fill"
        case .rain: "cloud.rain.fill"
        case .ocean: "water.waves"
        case .wind: "wind"
        }
    }
}

/// Generates meditation tones in real time with `AVAudioEngine` — no audio
/// files. For binaural modes the left ear gets the carrier frequency and the
/// right ear gets carrier + beat; the brain perceives the difference as a
/// slow pulse. All level changes are ramped over ~2 seconds so the tone
/// always fades in and out gently.
///
/// Audio continues when the app is backgrounded or the screen is locked
/// (the target declares the `audio` background mode), and the session is
/// published to the lock screen with working play/pause controls.
final class ToneEngine: ObservableObject {
    @Published private(set) var isPlaying = false

    var volume: Double = 0.6 {
        didSet { refreshTargets() }
    }

    var ambient: AmbientSound = .off {
        didSet {
            ambientKind = Self.kindIndex(of: ambient)
            refreshTargets()
        }
    }

    var ambientVolume: Double = 0.5 {
        didSet { refreshTargets() }
    }

    /// Pure sine tones sound far louder than music at the same level.
    private static let headroom = 0.25
    private static let ambientHeadroom = 0.16

    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private let sampleRate: Double = 44_100
    private var remoteCommandTargets: [(MPRemoteCommand, Any)] = []

    // State below is read by the audio render thread. Frequencies are only
    // written before the engine starts; amplitudes move via per-sample ramps.
    private var leftHz: Double = 200
    private var rightHz: Double = 206
    private var leftPhase: Double = 0
    private var rightPhase: Double = 0
    private var amplitude: Double = 0
    private var targetAmplitude: Double = 0

    // Ambient synthesis state (one generator per channel for stereo width).
    private var ambientKind = 0 // 0 off · 1 rain · 2 ocean · 3 wind
    private var ambientAmp = 0.0
    private var ambientTarget = 0.0
    private var clock = 0.0
    private var noiseSeed: [UInt32] = [0x1234_5678, 0x9ABC_DEF1]
    private var rainLP = [0.0, 0.0]
    private var brown = [0.0, 0.0]
    private var windLP = [0.0, 0.0]

    init() {
        registerRemoteCommands()
    }

    func start(mode: MeditationMode) {
        teardown()

        leftHz = mode.carrierHz
        rightHz = mode.carrierHz + mode.beatHz
        leftPhase = 0
        rightPhase = 0
        amplitude = 0
        ambientAmp = 0
        clock = 0
        rainLP = [0, 0]
        brown = [0, 0]
        windLP = [0, 0]

        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        let node = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self else { return noErr }
            let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let twoPi = 2.0 * Double.pi
            let leftStep = twoPi * self.leftHz / self.sampleRate
            let rightStep = twoPi * self.rightHz / self.sampleRate
            let ramp = 1.0 / (self.sampleRate * 2.0)        // ~2 s tone fade
            let ambientRamp = 1.0 / (self.sampleRate * 1.2) // ~1.2 s bed fade

            for frame in 0..<Int(frameCount) {
                self.amplitude = Self.step(self.amplitude, toward: self.targetAmplitude, by: ramp)
                self.ambientAmp = Self.step(self.ambientAmp, toward: self.ambientTarget, by: ambientRamp)
                self.clock += 1.0 / self.sampleRate

                var left = sin(self.leftPhase) * self.amplitude
                var right = sin(self.rightPhase) * self.amplitude
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
            refreshTargets()
            publishNowPlaying(mode: mode)
        } catch {
            print("ToneEngine failed to start: \(error)")
        }
    }

    func setPaused(_ paused: Bool) {
        guard sourceNode != nil else { return }
        isPlaying = !paused
        refreshTargets()
        updateNowPlayingRate()
    }

    /// Fades everything out, then releases the audio engine.
    func stop() {
        guard sourceNode != nil else { return }
        isPlaying = false
        refreshTargets()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) { [weak self] in
            guard let self, !self.isPlaying else { return }
            self.teardown()
        }
    }

    private func refreshTargets() {
        guard sourceNode != nil, isPlaying else {
            targetAmplitude = 0
            ambientTarget = 0
            return
        }
        targetAmplitude = volume * Self.headroom
        ambientTarget = ambient == .off ? 0 : ambientVolume * Self.ambientHeadroom
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

    private func ambientSample(channel ch: Int) -> Double {
        switch ambientKind {
        case 1: // Rain: low-passed white noise — a steady soft hiss.
            let w = white(ch)
            rainLP[ch] += 0.18 * (w - rainLP[ch])
            return rainLP[ch] * 2.4

        case 2: // Ocean: brown noise rising and falling in ~12 s swells.
            let w = white(ch)
            brown[ch] = (brown[ch] + 0.025 * w) * 0.997
            let phase = ch == 0 ? 0.0 : 0.35
            let swellWave = 0.5 + 0.5 * sin(2.0 * .pi * 0.055 * clock + phase)
            let swell = 0.30 + 0.70 * pow(swellWave, 1.6)
            return brown[ch] * 7.0 * swell

        case 3: // Wind: brown-ish noise whose brightness slowly drifts.
            let w = white(ch)
            let phase = ch == 0 ? 0.0 : 1.7
            let k = 0.018 + 0.014 * (0.5 + 0.5 * sin(2.0 * .pi * 0.045 * clock + phase))
            windLP[ch] += k * (w - windLP[ch])
            return windLP[ch] * 7.5

        default:
            return 0
        }
    }

    // MARK: - Lock screen integration

    private func publishNowPlaying(mode: MeditationMode) {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: mode.name,
            MPMediaItemPropertyArtist: "Resonance · \(mode.bandLabel)",
            MPNowPlayingInfoPropertyIsLiveStream: true,
            MPNowPlayingInfoPropertyPlaybackRate: 1.0,
        ]
    }

    private func updateNowPlayingRate() {
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
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
        for (command, target) in remoteCommandTargets {
            command.removeTarget(target)
        }
        engine.stop()
    }
}
