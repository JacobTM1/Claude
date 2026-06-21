import AVFoundation
import Speech

/// An always-on, on-device speech recognizer for the live journey. It runs for
/// the whole session and streams the latest transcript, so the session can
/// (a) catch the spoken "bring me back" exit phrase at any moment, and
/// (b) capture the user's reply at checkpoints from the same stream.
///
/// Voice processing (acoustic echo cancellation) is enabled on the input so
/// the guide's own voice is largely removed from what the mic hears — that's
/// what makes barge-in over the guide practical. On-device recognition keeps
/// it private and able to run continuously; the task auto-restarts if it ends.
final class ContinuousListener {
    /// Called on the main queue with the latest transcript of the current
    /// recognition segment.
    var onTranscript: ((String) -> Void)?

    /// Recognizer for the current interface language (English or Russian).
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: appLanguage.speechLocale))
    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var active = false

    static func requestPermissions() async -> Bool {
        let speech = await withCheckedContinuation { (c: CheckedContinuation<Bool, Never>) in
            SFSpeechRecognizer.requestAuthorization { c.resume(returning: $0 == .authorized) }
        }
        let mic = await withCheckedContinuation { (c: CheckedContinuation<Bool, Never>) in
            AVAudioApplication.requestRecordPermission { c.resume(returning: $0) }
        }
        return speech && mic
    }

    func start() {
        guard !active, let recognizer, recognizer.isAvailable else { return }
        active = true

        let input = engine.inputNode
        // Acoustic echo cancellation so the guide's voice isn't transcribed.
        try? input.setVoiceProcessingEnabled(true)

        let format = input.outputFormat(forBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }
        engine.prepare()
        do {
            try engine.start()
        } catch {
            active = false
            return
        }
        beginTask()
    }

    private func beginTask() {
        guard active, let recognizer else { return }
        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        if recognizer.supportsOnDeviceRecognition {
            req.requiresOnDeviceRecognition = true
        }
        request = req
        task = recognizer.recognitionTask(with: req) { [weak self] result, error in
            guard let self else { return }
            if let result {
                let text = result.bestTranscription.formattedString
                DispatchQueue.main.async { self.onTranscript?(text) }
            }
            if error != nil || (result?.isFinal ?? false) {
                // A segment ended (timeout/pause); start a fresh one so we keep
                // listening for the whole session.
                self.task = nil
                if self.active {
                    DispatchQueue.main.async { self.beginTask() }
                }
            }
        }
    }

    func stop() {
        active = false
        task?.cancel()
        task = nil
        request?.endAudio()
        request = nil
        if engine.isRunning {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
            try? engine.inputNode.setVoiceProcessingEnabled(false)
        }
    }
}
