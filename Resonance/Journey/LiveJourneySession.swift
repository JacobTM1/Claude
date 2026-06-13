import AVFoundation
import SwiftUI

/// Drives the interactive Journey of Souls: it asks the backend guide for the
/// next turn, speaks each line in the warm backend voice, holds the pauses,
/// and — at checkpoints — listens for the user's spoken reply and sends it
/// back. The guide (Claude, server-side) decides the arc and always grounds
/// the listener before completing. "Bring me back" works by voice or button.
@MainActor
final class LiveJourneySession: ObservableObject {
    enum Status { case preparing, speaking, listening, finished }

    @Published private(set) var status: Status = .preparing
    @Published private(set) var phaseTitle = "Settling In"
    @Published private(set) var currentText = ""
    @Published private(set) var isFinished = false
    @Published private(set) var errorMessage: String?

    private let themeName: String
    private let minutes: Int
    private let client = JourneyClient()
    private let voice = VoicePlayer()
    private let listener = SpeechListener()

    private var history: [ChatMsg] = []
    private var driveTask: Task<Void, Never>?

    init(themeName: String, minutes: Int) {
        self.themeName = themeName
        self.minutes = minutes
    }

    // MARK: - Lifecycle

    func begin() {
        configureAudioSession()
        Task { _ = await SpeechListener.requestPermissions() }
        startDrive(userSpeech: nil, first: true)
    }

    /// "Bring me back": stop whatever is happening and ask the guide to run
    /// the grounding return now. The system prompt routes this to RETURN.
    func bringMeBack() {
        voice.stop()
        listener.finish()
        let phrase = "Please bring me back now."
        history.append(ChatMsg(role: "user", text: phrase))
        startDrive(userSpeech: phrase, first: false)
    }

    /// Leaves the session entirely (user tapped End / closed the screen).
    func end() {
        driveTask?.cancel()
        voice.stop()
        listener.finish()
        deactivateAudioSession()
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
                response = try await client.turn(
                    theme: themeName, minutes: minutes,
                    history: history, userSpeech: pendingUserSpeech
                )
            } catch {
                // Never strand the listener — speak a gentle grounding and end.
                await deliver(fallbackReturn())
                return
            }
            if Task.isCancelled { return }

            let joined = response.speech.map(\.text).joined(separator: " ")
            if !joined.isEmpty {
                history.append(ChatMsg(role: "assistant", text: joined))
            }

            await deliver(response)
            if Task.isCancelled || isFinished { return }

            if response.awaitingResponse {
                status = .listening
                let said = await listener.listen()
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

    /// Speaks each line and holds its pause. Honors cancellation between steps.
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
                // No audio (e.g. TTS unavailable) — still let the line be read.
                try? await Task.sleep(nanoseconds: 2_200_000_000)
            }
            if Task.isCancelled { return }

            let pause = UInt64(max(line.pauseMsAfter, 0)) * 1_000_000
            try? await Task.sleep(nanoseconds: pause)
        }

        if response.sessionComplete {
            finish()
        }
    }

    private func finish() {
        isFinished = true
        status = .finished
        voice.stop()
        deactivateAudioSession()
    }

    private func fallbackReturn() -> TurnResponse {
        TurnResponse(
            speech: [
                GuideLine(text: "Let's gently begin to come back now.", pauseMsAfter: 5000),
                GuideLine(text: "Feel the surface beneath you, and the weight of your body resting on it.", pauseMsAfter: 5000),
                GuideLine(text: "Take a fuller breath, and when you're ready, let your eyes open. Welcome back.", pauseMsAfter: 3000),
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
            .playAndRecord, mode: .spokenAudio,
            options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP]
        )
        try? session.setActive(true)
    }

    private func deactivateAudioSession() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private static func title(for phase: String) -> String {
        switch phase {
        case "intro": "Settling In"
        case "induction": "Relaxing"
        case "deepening": "Going Deeper"
        case "journey": "The Journey"
        case "interlife": "Between Lives"
        case "integration": "Resting With It"
        case "returning": "Coming Back"
        case "reflection": "Reflection"
        default: phase.capitalized
        }
    }
}
