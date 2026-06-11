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
    @State private var totalSeconds = 600
    @State private var endFadeStarted = false
    @State private var showExtend = false
    @State private var volume = 0.6
    @State private var ambientChoice: AmbientSound = .off
    @State private var ambientLevel = 0.5
    /// 0 = controls tray fully shown … 1 = fully tucked away. Driven live
    /// by the drag gesture, so the tray tracks the finger like an iOS sheet.
    @State private var hideProgress: CGFloat = 0
    @State private var dragBase: CGFloat?
    @State private var trayHeight: CGFloat = 300

    /// The end-of-session fade begins this many seconds before zero, so the
    /// sound reaches silence right as the timer does.
    private let endFadeSeconds = 6

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
                if remainingSeconds <= endFadeSeconds && !endFadeStarted && remainingSeconds > 0 {
                    endFadeStarted = true
                    engine.fadeOutAndStop(over: Double(endFadeSeconds) + 0.5)
                }
                withAnimation(.easeInOut(duration: 0.6)) {
                    showExtend = remainingSeconds > 0 && remainingSeconds <= 12
                }
                if remainingSeconds <= 0 {
                    finishSession()
                }
            default:
                break
            }
        }
        .onChange(of: engine.isPlaying) { _, playing in
            // Keep the UI in sync when playback is toggled from the lock
            // screen — but not when the engine goes quiet because the
            // session's own ending fade has completed.
            if state == .running && !playing && !endFadeStarted {
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
                .transition(.opacity)

            VStack(spacing: 8) {
                Text(mode.breathing.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(mode.settleText)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
        }
        .animation(.easeInOut(duration: 0.85), value: countdown)
        .padding(32)
    }

    // MARK: - Running

    private var session: some View {
        ZStack(alignment: .bottom) {
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

                if showExtend {
                    Button(action: extendSession) {
                        Label("+5 minutes", systemImage: "plus")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(mode.colors[0].opacity(0.55), in: Capsule())
                    }
                    .padding(.bottom, 12)
                    .transition(.opacity.combined(with: .scale(scale: 0.92)))
                }

                timerPill

                // Quiet handle that grows in as the tray departs, inviting
                // the swipe (or tap) back up.
                Button {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.85)) {
                        hideProgress = 0
                    }
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.horizontal, 28)
                        .padding(.vertical, 9)
                        .background(.white.opacity(0.07), in: Capsule())
                }
                .opacity(Double(hideProgress))
                .frame(height: 44 * hideProgress)
                .padding(.top, 12 * hideProgress)
                .allowsHitTesting(hideProgress > 0.7)

                Spacer()
                    .frame(height: 24)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, (1 - hideProgress) * (trayHeight + 12))

            controls
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(key: TrayHeightKey.self, value: proxy.size.height)
                    }
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
                .offset(y: hideProgress * (trayHeight + 90))
        }
        .onPreferenceChange(TrayHeightKey.self) { trayHeight = $0 }
        .contentShape(Rectangle())
        .gesture(trayGesture)
    }

    /// Apple-sheet-style interactive drag: the tray is glued to the finger,
    /// can rest anywhere mid-gesture, and on release springs to the nearest
    /// edge — or follows a decisive flick regardless of position.
    private var trayGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                guard abs(value.translation.height) > abs(value.translation.width) else { return }
                if dragBase == nil { dragBase = hideProgress }
                let delta = value.translation.height / max(trayHeight, 1)
                hideProgress = min(max((dragBase ?? 0) + delta, 0), 1)
            }
            .onEnded { value in
                dragBase = nil
                let flick = value.velocity.height
                let target: CGFloat
                if flick > 250 {
                    target = 1
                } else if flick < -250 {
                    target = 0
                } else {
                    target = hideProgress > 0.5 ? 1 : 0
                }
                withAnimation(.spring(response: 0.42, dampingFraction: 0.85)) {
                    hideProgress = target
                }
            }
    }

    /// Remaining time as a soft glass pill with a slim progress ring —
    /// quieter and more organic than bare digits.
    private var timerPill: some View {
        let total = Double(totalSeconds)
        let progress = total > 0
            ? min(max(1.0 - Double(max(remainingSeconds, 0)) / total, 0), 1)
            : 0

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
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                Image(systemName: "waveform")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: 22)
                Slider(value: $volume, in: 0.05...1)
                    .tint(mode.colors[0])
                    .onChange(of: volume) { _, newValue in
                        engine.volume = newValue
                    }
                Image(systemName: "speaker.wave.3.fill")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.5))
            }

            ambiencePicker

            if ambientChoice != .off {
                HStack(spacing: 14) {
                    Image(systemName: ambientChoice.icon)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(width: 22)
                    Slider(value: $ambientLevel, in: 0.05...1)
                        .tint(mode.colors[0].opacity(0.7))
                        .onChange(of: ambientLevel) { _, newValue in
                            engine.ambientVolume = newValue
                        }
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
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
        .animation(.easeInOut(duration: 0.3), value: ambientChoice)
    }

    /// Ambient bed selector — synthesized live, so switching is seamless.
    private var ambiencePicker: some View {
        HStack(spacing: 8) {
            ForEach(AmbientSound.allCases) { sound in
                Button {
                    ambientChoice = sound
                    engine.ambient = sound
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: sound.icon)
                            .font(.subheadline)
                        Text(sound.rawValue)
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundStyle(.white.opacity(ambientChoice == sound ? 1 : 0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        ambientChoice == sound
                            ? AnyShapeStyle(mode.colors[0].opacity(0.55))
                            : AnyShapeStyle(.white.opacity(0.07)),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
                }
            }
        }
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
        totalSeconds = remainingSeconds
        endFadeStarted = false
        showExtend = false
        engine.volume = volume
        engine.ambient = ambientChoice
        engine.ambientVolume = ambientLevel
        engine.start(mode: mode)
        UIApplication.shared.isIdleTimerDisabled = true
        withAnimation(.easeInOut(duration: 0.6)) {
            state = .running
        }
    }

    private func extendSession() {
        remainingSeconds += 5 * 60
        totalSeconds += 5 * 60
        engine.cancelFadeOut()
        endFadeStarted = false
        withAnimation(.easeInOut(duration: 0.6)) {
            showExtend = false
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
        // On a natural ending the sound has already faded to silence; stop()
        // covers the pause-and-resume-in-the-final-seconds edge case.
        if engine.isPlaying {
            engine.stop()
        }
        UIApplication.shared.isIdleTimerDisabled = false
        showExtend = false
        withAnimation(.easeInOut(duration: 0.8)) { state = .finished }
    }

    private func endSession() {
        engine.stop()
        UIApplication.shared.isIdleTimerDisabled = false
        // Give the 1 s fade a moment so the sound drifts off rather than cuts.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            dismiss()
        }
    }
}

private struct TrayHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

#Preview {
    NavigationStack {
        SessionView(mode: MeditationMode.all[0])
    }
}
