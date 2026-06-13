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

                    Text("Journey of Souls")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("A calm, guided inner journey")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.7))

                    card(
                        title: "What this is",
                        icon: "sparkles",
                        body: "A contemplative, guided visualization. A gentle voice leads you through relaxation and calm inner imagery, with space to notice whatever arises — or to notice nothing at all. Both are completely fine."
                    )

                    card(
                        title: "What this isn't",
                        icon: "info.circle",
                        body: "This is inner experience, imagery, and reflection. It does not retrieve real past lives or any factual record of the past or an afterlife. It is not therapy, medical treatment, or a substitute for professional care."
                    )

                    card(
                        title: "Before you begin",
                        icon: "heart.text.square",
                        body: "Find a quiet, safe place where you can sit or lie down undisturbed. Please don't use this while driving or operating machinery, during acute distress, or under the influence of alcohol or other substances. You can gently end and return at any time."
                    )

                    if requiresAcknowledgment {
                        Button(action: {
                            onAcknowledge()
                            dismiss()
                        }) {
                            Text("I understand — continue")
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
                        Button("Done") { dismiss() }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(.white.opacity(0.14), in: Capsule())
                            .padding(.top, 6)
                    }

                    Text("If you ever feel distressed, gently open your eyes and return your attention to the room around you.")
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
