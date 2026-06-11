import SwiftUI
import UIKit

struct SessionView: View {
    let mode: MeditationMode

    private enum SessionState {
        case intro
        case countdown
        case running
        case paused
        case finished
    }

    @Environment(\.dismiss) private var dismiss
    @StateObject private var engine = ToneEngine()
    @State private var state: SessionState = .intro
    @State private var durationMinutes = 10
    @State private var remainingSeconds = 0
    @State private var countdown = 5
    @State private var volume = 0.6

    private let durations = [5, 10, 15, 20, 30]
    private let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            AuroraBackground(colors: mode.colors, intensity: state == .intro ? 0.7 : 1.0)

            if state != .intro {
                ParticleFieldView(motion: mode.particleMotion, tint: mode.colors[0])
                    .transition(.opacity)
            }

            switch state {
            case .intro:
                intro
            case .countdown:
                countdownView
            case .running, .paused:
                session
            case .finished:
                finished
            }
        }
        .navigationTitle(mode.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .onReceive(clock) { _ in
            switch state {
            case .countdown:
                if countdown > 1 {
                    countdown -= 1
                } else {
                    startSession()
                }
            case .running:
                remainingSeconds -= 1
                if remainingSeconds <= 0 {
                    finishSession()
                }
            default:
                break
            }
        }
        .onChange(of: engine.isPlaying) { _, playing in
            // Keep the UI in sync when playback is toggled from the lock screen.
            if state == .running && !playing {
                state = .paused
            } else if state == .paused && playing {
                state = .running
            }
        }
        .onDisappear {
            engine.stop()
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    // MARK: - Intro

    private var intro: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                frequencyBadge

                Text(mode.tagline)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 14) {
                    Label(mode.breathing.name, systemImage: "lungs.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(mode.breathing.summary)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text("How to practice")
                        .font(.headline)
                        .foregroundStyle(.white)
                    ForEach(Array(mode.guidance.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)")
                                .font(.footnote.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(width: 24, height: 24)
                                .background(mode.colors[0].opacity(0.6), in: Circle())
                            Text(step)
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.8))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassCard()

                durationPicker
                beginButton

                Text(mode.science)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.bottom, 24)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }

    private var frequencyBadge: some View {
        HStack(spacing: 10) {
            Image(systemName: "waveform")
            Text(mode.bandLabel)
                .fontWeight(.semibold)
            Text("·")
            Text(mode.frequencyDescription)
        }
        .font(.footnote)
        .foregroundStyle(.white.opacity(0.85))
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.white.opacity(0.10), in: Capsule())
    }

    private var durationPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Duration")
                .font(.headline)
                .foregroundStyle(.white)
            HStack(spacing: 8) {
                ForEach(durations, id: \.self) { minutes in
                    Button {
                        durationMinutes = minutes
                    } label: {
                        Text("\(minutes)m")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                durationMinutes == minutes
                                    ? AnyShapeStyle(mode.colors[0].opacity(0.65))
                                    : AnyShapeStyle(.white.opacity(0.08)),
                                in: Capsule()
                            )
                    }
                }
            }
        }
    }

    private var beginButton: some View {
        Button {
            countdown = 5
            withAnimation(.easeInOut(duration: 0.5)) {
                state = .countdown
            }
        } label: {
            Label("Begin Session", systemImage: "play.fill")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(colors: mode.colors, startPoint: .leading, endPoint: .trailing),
                    in: Capsule()
                )
        }
    }

    // MARK: - Countdown

    private var countdownView: some View {
        VStack(spacing: 26) {
            Text("Settle in")
                .font(.title3.weight(.medium))
                .foregroundStyle(.white.opacity(0.8))

            Text("\(countdown)")
                .font(.system(size: 110, weight: .thin, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()
                .id(countdown)
                .transition(
                    .asymmetric(
                        insertion: .scale(scale: 1.35).combined(with: .opacity),
                        removal: .opacity
                    )
                )

            VStack(spacing: 8) {
                Text(mode.breathing.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("Sit tall, soften your shoulders,\nand let your eyes rest.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
        }
        .animation(.easeOut(duration: 0.5), value: countdown)
        .padding(32)
    }

    // MARK: - Running

    private var session: some View {
        VStack(spacing: 0) {
            frequencyBadge
                .padding(.top, 8)

            Spacer()

            BreathingGuideView(
                pattern: mode.breathing,
                tint: mode.colors[0],
                isActive: state == .running
            )

            Spacer()

            timerPill

            controls
                .padding(.top, 18)
                .padding(.bottom, 28)
        }
        .padding(.horizontal, 20)
    }

    /// Remaining time as a soft glass pill with a slim progress ring —
    /// quieter and more organic than bare digits.
    private var timerPill: some View {
        let total = Double(durationMinutes * 60)
        let progress = total > 0 ? 1.0 - Double(max(remainingSeconds, 0)) / total : 0

        return HStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.14), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: mode.colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)
            }
            .frame(width: 26, height: 26)

            Text(formatTime(max(remainingSeconds, 0)))
                .font(.system(.title3, design: .rounded).weight(.light))
                .foregroundStyle(.white.opacity(0.92))
                .monospacedDigit()

            Text("remaining")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.45))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 11)
        .glassCard(cornerRadius: 26)
    }

    private var controls: some View {
        VStack(spacing: 18) {
            HStack(spacing: 14) {
                Image(systemName: "speaker.fill")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.5))
                Slider(value: $volume, in: 0.05...1)
                    .tint(mode.colors[0])
                    .onChange(of: volume) { _, newValue in
                        engine.volume = newValue
                    }
                Image(systemName: "speaker.wave.3.fill")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.5))
            }

            HStack(spacing: 16) {
                Button(action: togglePause) {
                    Label(
                        state == .running ? "Pause" : "Resume",
                        systemImage: state == .running ? "pause.fill" : "play.fill"
                    )
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.white.opacity(0.14), in: Capsule())
                }

                Button(action: endSession) {
                    Label("End", systemImage: "stop.fill")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.85))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(.white.opacity(0.07), in: Capsule())
                }
            }
        }
        .padding(18)
        .glassCard(cornerRadius: 28)
    }

    // MARK: - Finished

    private var finished: some View {
        VStack(spacing: 18) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(mode.colors[0])
            Text("Session complete")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
            Text("Take a moment before you move on.\nNotice how you feel.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: 220)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(colors: mode.colors, startPoint: .leading, endPoint: .trailing),
                        in: Capsule()
                    )
            }
            .padding(.top, 12)
        }
        .padding(32)
    }

    // MARK: - Actions

    private func startSession() {
        remainingSeconds = durationMinutes * 60
        engine.volume = volume
        engine.start(mode: mode)
        UIApplication.shared.isIdleTimerDisabled = true
        withAnimation(.easeInOut(duration: 0.6)) {
            state = .running
        }
    }

    private func togglePause() {
        if state == .running {
            engine.setPaused(true)
            state = .paused
        } else {
            engine.setPaused(false)
            state = .running
        }
    }

    private func finishSession() {
        engine.stop()
        UIApplication.shared.isIdleTimerDisabled = false
        withAnimation { state = .finished }
    }

    private func endSession() {
        engine.stop()
        UIApplication.shared.isIdleTimerDisabled = false
        dismiss()
    }
}

#Preview {
    NavigationStack {
        SessionView(mode: MeditationMode.all[0])
    }
}
