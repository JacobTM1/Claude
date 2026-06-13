import SwiftUI
import Combine

/// Drives a Journey of Souls session: the phase state machine, the voice +
/// ambient bed, the long silences, and — above all — the guarantee that a
/// grounding RETURN always runs before the session is complete and that the
/// user can gently leave at any moment.
///
/// All published mutations occur on the main thread (via the voice
/// completion callback, main-queue timers, and an explicit MainActor hop in
/// `begin`), so the UI stays consistent without actor-isolating the class.
final class JourneySession: ObservableObject {
    @Published private(set) var phase: JourneyPhase = .intro
    @Published private(set) var currentLine = ""
    @Published private(set) var isPaused = false
    @Published private(set) var isPreparing = true
    @Published private(set) var isFinished = false
    @Published private(set) var isReturning = false
    /// Shown when the session has sat paused long enough that the user may
    /// have stepped away — a gentle check-in, not an interruption.
    @Published var showCheckIn = false

    let theme: JourneyTheme
    private let minutes: Int
    private let adaptiveEnabled: Bool
    private let reflection: String?

    private let engine = ToneEngine()
    private let voice = VoiceGuide()

    private var script: [ScriptLine] = []
    private var index = 0
    private var silenceWork: DispatchWorkItem?
    private var silenceRemaining: TimeInterval = 0
    private var silenceStartedAt: Date?
    private var checkInWork: DispatchWorkItem?

    init(theme: JourneyTheme, minutes: Int, adaptiveEnabled: Bool, reflection: String?,
         voiceRate: Double, voicePitch: Double, voiceVolume: Double) {
        self.theme = theme
        self.minutes = minutes
        self.adaptiveEnabled = adaptiveEnabled
        self.reflection = reflection
        voice.rate = voiceRate
        voice.pitch = voicePitch
        voice.volume = voiceVolume
    }

    // MARK: - Lifecycle

    func begin() {
        isPreparing = true
        engine.volume = 0.30          // a soft tone, well under the voice
        engine.ambient = theme.ambient
        engine.ambientVolume = 0.55
        engine.start(
            carrierHz: theme.carrierHz,
            beatHz: theme.beatHz,
            pureTone: false,
            title: theme.name,
            subtitle: "Journey of Souls"
        )

        Task {
            let resolved = await JourneyScriptService.resolveScript(
                for: theme, minutes: minutes,
                adaptiveEnabled: adaptiveEnabled, reflection: reflection
            )
            await MainActor.run {
                self.script = resolved
                self.index = 0
                self.isPreparing = false
                // A breath of stillness before the first words.
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    self?.playCurrentLine()
                }
            }
        }
    }

    private func playCurrentLine() {
        guard !isPaused, !isFinished else { return }
        guard index < script.count else { complete(); return }

        let line = script[index]
        withAnimation(.easeInOut(duration: 0.8)) {
            phase = line.phase
            currentLine = line.text
            isReturning = line.phase.isGrounding
        }

        engine.setDucked(true)
        voice.speak(line.text) { [weak self] in
            guard let self, !self.isPaused else { return }
            self.engine.setDucked(false)
            self.beginSilence(seconds: Double(line.pauseMs) / 1000.0)
        }
    }

    private func beginSilence(seconds: TimeInterval) {
        silenceRemaining = seconds
        silenceStartedAt = Date()
        let work = DispatchWorkItem { [weak self] in
            guard let self, !self.isPaused else { return }
            self.index += 1
            self.playCurrentLine()
        }
        silenceWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: work)
    }

    // MARK: - Controls

    func togglePause() {
        isPaused ? resume() : pause()
    }

    private func pause() {
        isPaused = true
        voice.pause()
        if let started = silenceStartedAt {
            silenceRemaining -= Date().timeIntervalSince(started)
        }
        silenceWork?.cancel()
        engine.setPaused(true)
        scheduleCheckIn()
    }

    private func resume() {
        cancelCheckIn()
        isPaused = false
        engine.setPaused(false)
        if voice.isSpeaking {
            voice.resume()
        } else if silenceRemaining > 0.1 {
            beginSilence(seconds: silenceRemaining)
        } else {
            index += 1
            playCurrentLine()
        }
    }

    /// "Bring me back" — abandons the remaining script and runs an
    /// abbreviated grounding sequence. Never an abrupt stop.
    func bringMeBack() {
        cancelCheckIn()
        // If we're already in the grounding sequence, just let it finish.
        if isReturning && !isPaused { return }
        voice.stop()
        silenceWork?.cancel()
        isPaused = false
        engine.setPaused(false)
        script = JourneyScripts.quickReturn
        index = 0
        withAnimation(.easeInOut(duration: 0.8)) { isReturning = true }
        playCurrentLine()
    }

    private func complete() {
        isFinished = true
        withAnimation(.easeInOut(duration: 0.8)) {
            phase = .reflection
            currentLine = ""
        }
        voice.stop()
        engine.fadeOutAndStop(over: 6)
    }

    /// Called when the user taps Done on the reflection screen, or leaves.
    func end() {
        cancelCheckIn()
        silenceWork?.cancel()
        voice.stop()
        engine.stop()
    }

    // MARK: - Idle check-in

    private func scheduleCheckIn() {
        cancelCheckIn()
        let work = DispatchWorkItem { [weak self] in
            guard let self, self.isPaused, !self.isFinished else { return }
            self.showCheckIn = true
        }
        checkInWork = work
        // If left paused for two minutes, gently check in.
        DispatchQueue.main.asyncAfter(deadline: .now() + 120, execute: work)
    }

    private func cancelCheckIn() {
        checkInWork?.cancel()
        checkInWork = nil
        showCheckIn = false
    }
}
