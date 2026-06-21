import AVFoundation
import SwiftUI

/// Drives the interactive Journey of Souls. The backend guide (Claude) decides
/// the arc and always grounds the listener before completing; the warm backend
/// voice speaks each line; an always-on on-device listener lets the user say
/// "bring me back" at any moment and supplies their spoken replies at
/// checkpoints from the same stream.
@MainActor
final class LiveJourneySession: ObservableObject {
    enum Status { case preparing, speaking, listening, finished }

    @Published private(set) var status: Status = .preparing
    @Published private(set) var phaseTitle = L("Settling In", "Устройство")
    @Published private(set) var currentText = ""
    @Published private(set) var isFinished = false

    private let themeName: String
    private let minutes: Int
    private let client = JourneyClient()
    private let voice = VoicePlayer()
    private let listener = ContinuousListener()

    private let goal = UserGoalStore.phrase
    private var history: [ChatMsg] = []
    private var driveTask: Task<Void, Never>?
    private var startedAt: Date?

    // Checkpoint capture (drawn from the continuous transcript stream).
    private var capturing = false
    private var capturedReply = ""
    private var replyContinuation: CheckedContinuation<String, Never>?
    private var silenceWork: DispatchWorkItem?

    // Once we begin returning, stop reacting to the exit phrase (and the guide
    // itself may say "come back" during grounding).
    private var returning = false

    private let exitPhrases = [
        // English
        "bring me back", "take me back", "i want to come back", "want to come back",
        "wake me up", "end the session", "stop the session", "come back now",
        // Russian
        "верни меня", "вернуться", "хочу вернуться", "разбуди меня",
        "закончить", "останови", "верни обратно", "хочу обратно",
    ]

    init(themeName: String, minutes: Int) {
        self.themeName = themeName
        self.minutes = minutes
    }

    // MARK: - Lifecycle

    func begin() {
        startedAt = Date()
        configureAudioSession()
        listener.onTranscript = { [weak self] text in
            Task { @MainActor in self?.handleTranscript(text) }
        }
        Task {
            _ = await ContinuousListener.requestPermissions()
            self.listener.start()
        }
        startDrive(userSpeech: nil, first: true)
    }

    func bringMeBack() {
        guard !returning else { return }
        returning = true
        endCapture()
        voice.stop()
        let phrase = L("Please bring me back now.", "Пожалуйста, верни меня сейчас.")
        history.append(ChatMsg(role: "user", text: phrase))
        startDrive(userSpeech: phrase, first: false)
    }

    func end() {
        driveTask?.cancel()
        voice.stop()
        listener.stop()
        endCapture()
        deactivateAudioSession()
    }

    // MARK: - Transcript handling (always-on)

    private func handleTranscript(_ text: String) {
        let lower = text.lowercased()

        // Spoken exit — works at any moment until we're already returning.
        if !returning, exitPhrases.contains(where: { lower.contains($0) }) {
            bringMeBack()
            return
        }

        // Feed checkpoint capture.
        if capturing {
            capturedReply = text
            armSilence()
        }
    }

    private func awaitReply() async -> String {
        await withCheckedContinuation { (cont: CheckedContinuation<String, Never>) in
            replyContinuation = cont
            capturedReply = ""
            capturing = true
            armSilence()
            // Hard cap so a checkpoint never hangs.
            DispatchQueue.main.asyncAfter(deadline: .now() + 18) { [weak self] in
                self?.endCapture()
            }
        }
    }

    private func armSilence() {
        silenceWork?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.endCapture() }
        silenceWork = work
        // End shortly after they stop speaking.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2, execute: work)
    }

    private func endCapture() {
        silenceWork?.cancel()
        silenceWork = nil
        guard capturing else { return }
        capturing = false
        let cont = replyContinuation
        replyContinuation = nil
        cont?.resume(returning: capturedReply)
    }

    // MARK: - Drive loop

    private func startDrive(userSpeech: String?, first: Bool) {
        driveTask?.cancel()
        driveTask = Task { await self.loop(initialUserSpeech: userSpeech, first: first) }
    }

    private func loop(initialUserSpeech: String?, first: Bool) async {
        var pendingUserSpeech = first ? nil : initialUserSpeech

        while !Task.isCancelled && !isFinished {
            status = .preparing
            let response: TurnResponse
            do {
                let elapsed = startedAt.map { Int(Date().timeIntervalSince($0)) }
                response = try await client.turn(
                    theme: themeName, minutes: minutes,
                    history: history, userSpeech: pendingUserSpeech,
                    goal: goal.isEmpty ? nil : goal,
                    language: appLanguage.backendName,
                    elapsedSeconds: elapsed
                )
            } catch {
                await deliver(fallbackReturn())
                return
            }
            if Task.isCancelled { return }

            let joined = response.speech.map(\.text).joined(separator: " ")
            if !joined.isEmpty {
                history.append(ChatMsg(role: "assistant", text: joined))
            }
            if response.phase == "returning" { returning = true }

            await deliver(response)
            if Task.isCancelled || isFinished { return }

            if response.awaitingResponse {
                status = .listening
                let said = await awaitReply()
                if Task.isCancelled { return }
                let trimmed = said.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    history.append(ChatMsg(role: "user", text: trimmed))
                }
                pendingUserSpeech = trimmed.isEmpty ? nil : trimmed
            } else {
                pendingUserSpeech = nil
            }
        }
    }

    private func deliver(_ response: TurnResponse) async {
        withAnimation(.easeInOut(duration: 0.8)) {
            phaseTitle = Self.title(for: response.phase)
        }
        status = .speaking

        for line in response.speech {
            if Task.isCancelled { return }
            withAnimation(.easeInOut(duration: 0.6)) { currentText = line.text }

            if let audio = try? await client.tts(text: line.text), !audio.isEmpty {
                await voice.play(audio)
            } else {
                try? await Task.sleep(nanoseconds: 2_200_000_000)
            }
            if Task.isCancelled { return }
            try? await Task.sleep(nanoseconds: UInt64(max(line.pauseMsAfter, 0)) * 1_000_000)
        }

        if response.sessionComplete { finish() }
    }

    private func finish() {
        isFinished = true
        status = .finished
        voice.stop()
        listener.stop()
        deactivateAudioSession()
    }

    private func fallbackReturn() -> TurnResponse {
        returning = true
        return TurnResponse(
            speech: [
                GuideLine(text: L("Let's gently begin to come back now.",
                                  "Давайте мягко начнём возвращаться."), pauseMsAfter: 5000),
                GuideLine(text: L("Feel the surface beneath you, and the weight of your body resting on it.",
                                  "Почувствуйте поверхность под собой и вес тела, опирающегося на неё."), pauseMsAfter: 5000),
                GuideLine(text: L("Take a fuller breath, and when you're ready, let your eyes open. Welcome back.",
                                  "Сделайте более полный вдох и, когда будете готовы, откройте глаза. С возвращением."), pauseMsAfter: 3000),
            ],
            phase: "returning",
            awaitingResponse: false,
            sessionComplete: true
        )
    }

    // MARK: - Audio session

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(
            .playAndRecord, mode: .voiceChat,
            options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP]
        )
        try? session.setActive(true)
    }

    private func deactivateAudioSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private static func title(for phase: String) -> String {
        switch phase {
        case "intro": L("Settling In", "Устройство")
        case "induction": L("Relaxing", "Расслабление")
        case "deepening": L("Going Deeper", "Углубление")
        case "journey": L("The Journey", "Путешествие")
        case "interlife": L("Between Lives", "Между жизнями")
        case "integration": L("Resting With It", "Покой с этим")
        case "returning": L("Coming Back", "Возвращение")
        case "reflection": L("Reflection", "Отражение")
        default: phase.capitalized
        }
    }
}
