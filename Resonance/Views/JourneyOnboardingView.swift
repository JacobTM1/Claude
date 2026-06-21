import SwiftUI

/// First-entry intro + wellbeing gate for Journey of Souls. Explains what
/// the experience is and isn't, sets expectations for a safe setting, and
/// requires a simple acknowledgment. Reused from Settings as a read-only
/// review (no acknowledgment needed there).
struct JourneyOnboardingView: View {
    /// When true, shows the "I understand" acknowledgment button; when false
    /// (review from Settings), shows a plain Done.
    var requiresAcknowledgment = true
    var onAcknowledge: () -> Void = {}
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AuroraBackground(
                colors: [Color(red: 0.16, green: 0.20, blue: 0.46),
                         Color(red: 0.10, green: 0.10, blue: 0.28)],
                intensity: 1.0
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.white)
                        .padding(.top, 12)

                    Text(L("Journey of Souls", "Путешествие душ"))
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(L("A calm, guided inner journey", "Спокойное внутреннее путешествие с проводником"))
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.7))

                    card(
                        title: L("What this is", "Что это"),
                        icon: "sparkles",
                        body: L("A contemplative, guided visualization. A gentle voice leads you through relaxation and calm inner imagery, with space to notice whatever arises — or to notice nothing at all. Both are completely fine.",
                                "Созерцательная управляемая визуализация. Мягкий голос ведёт вас через расслабление и спокойные внутренние образы, оставляя место заметить то, что приходит, — или не заметить ничего. И то и другое совершенно нормально.")
                    )

                    card(
                        title: L("What this isn't", "Чем это не является"),
                        icon: "info.circle",
                        body: L("This is inner experience, imagery, and reflection. It does not retrieve real past lives or any factual record of the past or an afterlife. It is not therapy, medical treatment, or a substitute for professional care.",
                                "Это внутренний опыт, образы и размышление. Это не извлечение реальных прошлых жизней и не фактическая запись прошлого или загробной жизни. Это не терапия, не лечение и не замена профессиональной помощи.")
                    )

                    card(
                        title: L("Before you begin", "Прежде чем начать"),
                        icon: "heart.text.square",
                        body: L("Find a quiet, safe place where you can sit or lie down undisturbed. Please don't use this while driving or operating machinery, during acute distress, or under the influence of alcohol or other substances. You can gently end and return at any time.",
                                "Найдите тихое, безопасное место, где можно сесть или лечь, не отвлекаясь. Пожалуйста, не используйте это за рулём или у механизмов, в состоянии острого стресса или под действием алкоголя и других веществ. Вы можете мягко завершить и вернуться в любой момент.")
                    )

                    if requiresAcknowledgment {
                        Button(action: {
                            onAcknowledge()
                            dismiss()
                        }) {
                            Text(L("I understand — continue", "Я понимаю — продолжить"))
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [Color(red: 0.32, green: 0.36, blue: 0.8),
                                                 Color(red: 0.5, green: 0.36, blue: 0.82)],
                                        startPoint: .leading, endPoint: .trailing
                                    ),
                                    in: Capsule()
                                )
                        }
                        .padding(.top, 6)
                    } else {
                        Button(L("Done", "Готово")) { dismiss() }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(.white.opacity(0.14), in: Capsule())
                            .padding(.top, 6)
                    }

                    Text(L("If you ever feel distressed, gently open your eyes and return your attention to the room around you.",
                           "Если вам станет тревожно, мягко откройте глаза и верните внимание к комнате вокруг вас."))
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.bottom, 24)
                }
                .padding(.horizontal, 20)
            }
        }
        .interactiveDismissDisabled(requiresAcknowledgment)
    }

    private func card(title: String, icon: String, body text: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(.white)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }
}

#Preview {
    JourneyOnboardingView()
}
