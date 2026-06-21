import SwiftUI

/// The Journey of Souls player. Deliberately minimal and dim during the
/// session: a slow breathing glow, the current spoken line, and two always-
/// reachable controls — pause, and a persistent "Bring me back" that runs
/// the gentle grounding sequence. Ends on a quiet reflection screen.
struct JourneySessionView: View {
    let theme: JourneyTheme
    let minutes: Int
    let adaptiveEnabled: Bool
    let reflection: String?

    @Environment(\.dismiss) private var dismiss
    @StateObject private var session: JourneySession

    init(theme: JourneyTheme, minutes: Int, adaptiveEnabled: Bool, reflection: String?) {
        self.theme = theme
        self.minutes = minutes
        self.adaptiveEnabled = adaptiveEnabled
        self.reflection = reflection
        let rate = UserDefaults.standard.object(forKey: "voiceRate") as? Double ?? 0.5
        let pitch = UserDefaults.standard.object(forKey: "voicePitch") as? Double ?? 0.45
        let vol = UserDefaults.standard.object(forKey: "voiceVolume") as? Double ?? 0.95
        _session = StateObject(wrappedValue: JourneySession(
            theme: theme, minutes: minutes, adaptiveEnabled: adaptiveEnabled,
            reflection: reflection, voiceRate: rate, voicePitch: pitch, voiceVolume: vol
        ))
    }

    var body: some View {
        ZStack {
            AuroraBackground(colors: theme.colors, intensity: 0.9)

            if session.isFinished {
                reflectionView
            } else {
                activeView
            }

            if session.showCheckIn {
                checkInOverlay
            }
        }
        .onAppear { session.begin() }
        .onDisappear { session.end() }
        .statusBarHidden(true)
    }

    // MARK: - Active session

    private var activeView: some View {
        VStack(spacing: 0) {
            Text(session.phase.title.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(3)
                .foregroundStyle(.white.opacity(0.5))
                .padding(.top, 24)

            Spacer()

            BreathingGlow(tint: .white)
                .frame(width: 260, height: 260)

            Spacer().frame(height: 36)

            Text(session.isPreparing ? L("Settling in…", "Устраиваемся…") : session.currentLine)
                .font(.title3.weight(.regular))
                .foregroundStyle(.white.opacity(0.92))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 32)
                .frame(minHeight: 120, alignment: .top)
                .animation(.easeInOut(duration: 0.6), value: session.currentLine)

            Spacer()

            controls
                .padding(.bottom, 40)
        }
    }

    private var controls: some View {
        VStack(spacing: 18) {
            // Pause / resume — secondary.
            if !session.isReturning {
                Button(action: session.togglePause) {
                    Image(systemName: session.isPaused ? "play.fill" : "pause.fill")
                        .font(.title3)
                        .foregroundStyle(.white.opacity(0.9))
                        .frame(width: 60, height: 60)
                        .background(.white.opacity(0.10), in: Circle())
                }
            }

            // Bring me back — always present, always reachable.
            Button(action: session.bringMeBack) {
                Label(session.isReturning ? L("Returning…", "Возвращаемся…") : L("Bring me back", "Верни меня"),
                      systemImage: "arrow.down.heart")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(.white.opacity(0.12), in: Capsule())
            }
            .disabled(session.isReturning)
        }
    }

    // MARK: - Reflection

    private var reflectionView: some View {
        VStack(spacing: 18) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 52))
                .foregroundStyle(.white)
            Text(L("Welcome back", "С возвращением"))
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
            Text(L("Take a moment before moving on.\nNotice how you feel now,\ncompared to when you began.",
                   "Не торопитесь продолжать.\nЗаметьте, как вы себя чувствуете сейчас,\nпо сравнению с началом."))
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Button {
                dismiss()
            } label: {
                Text(L("Done", "Готово"))
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: 220)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(colors: theme.colors, startPoint: .leading, endPoint: .trailing),
                        in: Capsule()
                    )
            }
            .padding(.top, 14)
        }
        .padding(32)
        .transition(.opacity)
    }

    // MARK: - Gentle idle check-in

    private var checkInOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: 18) {
                Text(L("Still here?", "Вы здесь?"))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                Text(L("Your journey is paused. Take your time —\nyou can continue, or gently come back.",
                       "Ваше путешествие на паузе. Не спешите —\nможно продолжить или мягко вернуться."))
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                HStack(spacing: 14) {
                    Button(L("Continue", "Продолжить")) {
                        session.showCheckIn = false
                        session.togglePause()
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.vertical, 12).frame(maxWidth: .infinity)
                    .background(.white.opacity(0.14), in: Capsule())

                    Button(L("Bring me back", "Верни меня")) {
                        session.showCheckIn = false
                        session.bringMeBack()
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.vertical, 12).frame(maxWidth: .infinity)
                    .background(theme.colors[0].opacity(0.6), in: Capsule())
                }
            }
            .padding(26)
            .glassCard(cornerRadius: 24)
            .padding(.horizontal, 36)
        }
        .transition(.opacity)
    }
}

/// A slow, soft breathing glow — the only motion during a journey, kept
/// minimal so the experience stays distraction-free.
private struct BreathingGlow: View {
    let tint: Color

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            // ~5.5 breaths/min, the slow resonant pace.
            let pulse = 0.5 + 0.5 * sin(t * (2 * .pi / 11.0))
            ZStack {
                Circle()
                    .fill(tint.opacity(0.06))
                    .scaleEffect(0.9 + 0.18 * pulse)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [tint.opacity(0.5), tint.opacity(0.04)],
                            center: .center, startRadius: 6, endRadius: 130
                        )
                    )
                    .scaleEffect(0.7 + 0.26 * pulse)
                    .blur(radius: 8)
            }
        }
    }
}

#Preview {
    JourneySessionView(theme: JourneyTheme.all[0], minutes: 15,
                       adaptiveEnabled: false, reflection: nil)
}
