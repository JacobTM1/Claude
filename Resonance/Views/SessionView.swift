import SwiftUI

struct SessionView: View {
    let mode: MeditationMode

    private enum SessionState {
        case intro
        case running
        case paused
        case finished
    }

    @Environment(\.dismiss) private var dismiss
    @StateObject private var engine = ToneEngine()
    @State private var state: SessionState = .intro
    @State private var durationMinutes = 10
    @State private var remainingSeconds = 0
    @State private var volume = 0.6

    private let durations = [5, 10, 15, 20, 30]
    private let clock = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Theme.sessionBackground(for: mode).ignoresSafeArea()

            switch state {
            case .intro:
                intro
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
            guard state == .running else { return }
            remainingSeconds -= 1
            if remainingSeconds <= 0 {
                engine.stop()
                withAnimation { state = .finished }
            }
        }
        .onDisappear {
            engine.stop()
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
        Button(action: begin) {
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

            Text(formatTime(max(remainingSeconds, 0)))
                .font(.system(size: 44, weight: .light, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()

            controls
                .padding(.top, 20)
                .padding(.bottom, 28)
        }
        .padding(.horizontal, 20)
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

    private func begin() {
        remainingSeconds = durationMinutes * 60
        engine.volume = volume
        engine.start(mode: mode)
        withAnimation(.easeInOut(duration: 0.5)) {
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

    private func endSession() {
        engine.stop()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        SessionView(mode: MeditationMode.all[0])
    }
}
