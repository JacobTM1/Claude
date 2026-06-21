import SwiftUI

/// The interactive Journey of Souls player. A warm backend voice guides the
/// session over a slow breathing glow; at checkpoints a soft "listening"
/// state invites the user to simply speak. The grounding "Bring me back"
/// control is always present and also works by voice.
struct LiveJourneySessionView: View {
    let theme: JourneyTheme
    let minutes: Int

    @Environment(\.dismiss) private var dismiss
    @StateObject private var session: LiveJourneySession

    init(theme: JourneyTheme, minutes: Int) {
        self.theme = theme
        self.minutes = minutes
        _session = StateObject(wrappedValue: LiveJourneySession(
            themeName: theme.name, minutes: minutes
        ))
    }

    var body: some View {
        ZStack {
            CosmicBackground(colors: theme.colors)

            if session.isFinished {
                reflectionView
            } else {
                activeView
            }
        }
        .onAppear { session.begin() }
        .onDisappear { session.end() }
        .statusBarHidden(true)
    }

    private var activeView: some View {
        VStack(spacing: 0) {
            Text(session.phaseTitle.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(3)
                .foregroundStyle(.white.opacity(0.5))
                .padding(.top, 24)
                .animation(.easeInOut(duration: 0.6), value: session.phaseTitle)

            Spacer()

            JourneyGlow(tint: .white, listening: session.status == .listening)
                .frame(width: 260, height: 260)

            Spacer().frame(height: 34)

            Text(spokenOrStatusText)
                .font(.title3.weight(.regular))
                .foregroundStyle(.white.opacity(0.92))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 32)
                .frame(minHeight: 120, alignment: .top)
                .animation(.easeInOut(duration: 0.5), value: spokenOrStatusText)

            if session.status == .listening {
                Label(L("Listening — speak softly", "Слушаю — говорите тихо"), systemImage: "waveform")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.top, 4)
            }

            Spacer()

            VStack(spacing: 8) {
                Button(action: session.bringMeBack) {
                    Label(L("Bring me back", "Верни меня"), systemImage: "arrow.down.heart")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.horizontal, 22)
                        .padding(.vertical, 12)
                        .background(.white.opacity(0.12), in: Capsule())
                }
                Text(L("…or just say “bring me back”", "…или просто скажите «верни меня»"))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(.bottom, 40)
        }
    }

    private var spokenOrStatusText: String {
        if session.status == .preparing && session.currentText.isEmpty {
            return L("Settling in…", "Устраиваемся…")
        }
        return session.currentText
    }

    private var reflectionView: some View {
        VStack(spacing: 18) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 52))
                .foregroundStyle(.white)
            Text(L("Welcome back", "С возвращением"))
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
            Text(L("Take a moment before moving on.\nNotice how you feel now.",
                   "Не торопитесь продолжать.\nЗаметьте, как вы себя чувствуете сейчас."))
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
}

/// A slow breathing glow that brightens and quickens slightly while the
/// session is listening, so silence still feels alive and responsive.
private struct JourneyGlow: View {
    let tint: Color
    var listening: Bool

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let period = listening ? 4.0 : 11.0
            let pulse = 0.5 + 0.5 * sin(t * (2 * .pi / period))
            ZStack {
                Circle()
                    .fill(tint.opacity(listening ? 0.10 : 0.06))
                    .scaleEffect(0.9 + 0.18 * pulse)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [tint.opacity(listening ? 0.6 : 0.5), tint.opacity(0.04)],
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
    LiveJourneySessionView(theme: JourneyTheme.all[0], minutes: 15)
}
