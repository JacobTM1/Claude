import AVFoundation
import Combine
import MediaPlayer

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
        didSet {
            if isPlaying { targetAmplitude = volume * Self.headroom }
        }
    }

    /// Pure sine tones sound far louder than music at the same level.
    private static let headroom = 0.25

    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private let sampleRate: Double = 44_100
    private var remoteCommandTargets: [(MPRemoteCommand, Any)] = []

    // State below is read by the audio render thread. Frequencies are only
    // written before the engine starts; amplitude moves via the ramp.
    private var leftHz: Double = 200
    private var rightHz: Double = 206
    private var leftPhase: Double = 0
    private var rightPhase: Double = 0
    private var amplitude: Double = 0
    private var targetAmplitude: Double = 0

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
        targetAmplitude = volume * Self.headroom

        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        let node = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self else { return noErr }
            let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let twoPi = 2.0 * Double.pi
            let leftStep = twoPi * self.leftHz / self.sampleRate
            let rightStep = twoPi * self.rightHz / self.sampleRate
            let ramp = 1.0 / (self.sampleRate * 2.0) // ~2 s fade between levels

            for frame in 0..<Int(frameCount) {
                if self.amplitude < self.targetAmplitude {
                    self.amplitude = min(self.amplitude + ramp, self.targetAmplitude)
                } else if self.amplitude > self.targetAmplitude {
                    self.amplitude = max(self.amplitude - ramp, self.targetAmplitude)
                }

                let left = Float(sin(self.leftPhase) * self.amplitude)
                let right = Float(sin(self.rightPhase) * self.amplitude)
                self.leftPhase += leftStep
                if self.leftPhase > twoPi { self.leftPhase -= twoPi }
                self.rightPhase += rightStep
                if self.rightPhase > twoPi { self.rightPhase -= twoPi }

                for (channel, buffer) in buffers.enumerated() {
                    let samples = UnsafeMutableBufferPointer<Float>(buffer)
                    samples[frame] = channel == 0 ? left : right
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
            publishNowPlaying(mode: mode)
        } catch {
            print("ToneEngine failed to start: \(error)")
        }
    }

    func setPaused(_ paused: Bool) {
        guard sourceNode != nil else { return }
        targetAmplitude = paused ? 0 : volume * Self.headroom
        isPlaying = !paused
        updateNowPlayingRate()
    }

    /// Fades the tone out, then releases the audio engine.
    func stop() {
        guard sourceNode != nil else { return }
        targetAmplitude = 0
        isPlaying = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) { [weak self] in
            guard let self, !self.isPlaying else { return }
            self.teardown()
        }
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
