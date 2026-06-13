import AVFoundation
import Speech

/// On-device speech-to-text for checkpoint listening. Captures one short
/// spoken reply and returns the transcript, ending on a couple of seconds of
/// silence or a hard timeout. Returns "" if nothing was heard or permission
/// was denied — the guide treats that as a quiet moment.
final class SpeechListener {
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var silenceTimer: Timer?
    private var continuation: CheckedContinuation<String, Never>?
    private var latest = ""

    /// Requests microphone + speech-recognition permission. Returns true only
    /// if both are granted.
    static func requestPermissions() async -> Bool {
        let speech = await withCheckedContinuation { (c: CheckedContinuation<Bool, Never>) in
            SFSpeechRecognizer.requestAuthorization { status in
                c.resume(returning: status == .authorized)
            }
        }
        let mic = await withCheckedContinuation { (c: CheckedContinuation<Bool, Never>) in
            AVAudioApplication.requestRecordPermission { granted in
                c.resume(returning: granted)
            }
        }
        return speech && mic
    }

    /// Listens for one reply. Resolves with the best transcript heard.
    func listen(maxSeconds: Double = 15) async -> String {
        await withCheckedContinuation { (cont: CheckedContinuation<String, Never>) in
            continuation = cont
            latest = ""

            guard let recognizer, recognizer.isAvailable else { finish(); return }

            let req = SFSpeechAudioBufferRecognitionRequest()
            req.shouldReportPartialResults = true
            request = req

            let input = engine.inputNode
            let format = input.outputFormat(forBus: 0)
            input.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                req.append(buffer)
            }
            engine.prepare()
            do {
                try engine.start()
            } catch {
                finish()
                return
            }

            task = recognizer.recognitionTask(with: req) { [weak self] result, error in
                guard let self else { return }
                if let result {
                    let text = result.bestTranscription.formattedString
                    DispatchQueue.main.async {
                        self.latest = text
                        self.resetSilenceTimer()
                    }
                }
                if error != nil || (result?.isFinal ?? false) {
                    self.finish()
                }
            }

            DispatchQueue.main.async {
                self.resetSilenceTimer()
                // Hard cap so a session never hangs waiting on the mic.
                DispatchQueue.main.asyncAfter(deadline: .now() + maxSeconds) { [weak self] in
                    self?.finish()
                }
            }
        }
    }

    /// Ends listening (used by "bring me back" / pause). Safe to call twice.
    func finish() {
        DispatchQueue.main.async { self._finish() }
    }

    private func resetSilenceTimer() {
        silenceTimer?.invalidate()
        // End shortly after the speaker stops talking.
        silenceTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { [weak self] _ in
            self?.finish()
        }
    }

    private func _finish() {
        silenceTimer?.invalidate()
        silenceTimer = nil
        task?.cancel()
        task = nil
        request?.endAudio()
        request = nil
        if engine.isRunning {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }
        guard let cont = continuation else { return }
        continuation = nil
        cont.resume(returning: latest)
    }
}
