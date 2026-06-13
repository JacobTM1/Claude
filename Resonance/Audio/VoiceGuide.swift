import AVFoundation
import Combine

/// A slow, warm guiding voice built on the on-device speech synthesizer —
/// no network, no accounts. It speaks one line at a time and reports when
/// each line finishes, so the session can hold the long silences that make
/// an induction work, and so the ambient bed can duck only while words play.
final class VoiceGuide: NSObject, ObservableObject {
    @Published private(set) var isSpeaking = false

    /// 0…1 user-facing pacing controls (mapped to synth ranges internally).
    var rate: Double = 0.5      // slower than normal speech
    var pitch: Double = 0.45    // low, calm register
    var volume: Double = 0.95

    private let synth = AVSpeechSynthesizer()
    private var onFinish: (() -> Void)?

    override init() {
        super.init()
        synth.delegate = self
    }

    /// Speaks one line, then calls `completion` when it finishes (or is
    /// interrupted). Completion always fires on the main queue exactly once.
    func speak(_ text: String, completion: @escaping () -> Void) {
        onFinish = completion
        let utterance = AVSpeechUtterance(string: text)
        // Map 0…1 onto a calm, deliberately slow band.
        let minRate = AVSpeechUtteranceMinimumSpeechRate
        let slowCeiling = AVSpeechUtteranceDefaultSpeechRate * 0.9
        utterance.rate = minRate + Float(rate) * (slowCeiling - minRate)
        utterance.pitchMultiplier = 0.5 + Float(pitch) * 0.7 // ~0.5…1.2
        utterance.volume = Float(volume)
        utterance.preUtteranceDelay = 0.15
        utterance.postUtteranceDelay = 0.0
        if let voice = Self.preferredVoice() {
            utterance.voice = voice
        }
        isSpeaking = true
        synth.speak(utterance)
    }

    func pause() {
        synth.pauseSpeaking(at: .word)
    }

    func resume() {
        synth.continueSpeaking()
    }

    /// Stops immediately and drops any pending completion (so an aborted
    /// line never advances the state machine behind our back).
    func stop() {
        onFinish = nil
        isSpeaking = false
        synth.stopSpeaking(at: .immediate)
    }

    /// Prefer a higher-quality/enhanced English voice when the device has
    /// one downloaded; otherwise fall back to the default.
    private static func preferredVoice() -> AVSpeechSynthesisVoice? {
        let english = AVSpeechSynthesisVoice.speechVoices().filter {
            $0.language.hasPrefix("en")
        }
        if let enhanced = english.first(where: { $0.quality == .premium })
            ?? english.first(where: { $0.quality == .enhanced }) {
            return enhanced
        }
        return AVSpeechSynthesisVoice(language: "en-US")
    }
}

extension VoiceGuide: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let finish = onFinish
        onFinish = nil
        DispatchQueue.main.async {
            self.isSpeaking = false
            finish?()
        }
    }
}
