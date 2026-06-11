import SwiftUI

/// An honest explainer of what the app does and how strong the evidence is
/// for each component.
struct ScienceView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        section(
                            title: "How Resonance works",
                            icon: "waveform.path",
                            body: "Each session pairs a generated tone with a matched breathing pattern. The tone gives your mind a steady anchor; the breathing does measurable physiological work. Used together for 10–20 minutes, they make it much easier to settle into a meditative state."
                        )

                        section(
                            title: "Binaural beats",
                            icon: "headphones",
                            body: "When each ear hears a slightly different frequency (say 200 Hz and 206 Hz), the brain perceives a 6 Hz pulse — the difference. The beat frequency targets an EEG band: delta (0.5–4 Hz) for sleep, theta (4–8 Hz) for deep meditation, alpha (8–12 Hz) for relaxed calm, and gamma (~40 Hz) for attention. A 2019 meta-analysis (Garcia-Argibay et al.) found measurable effects on anxiety, attention and memory, though the research is still young and effects vary by person. Stereo headphones are essential — the effect cannot exist through speakers."
                        )

                        section(
                            title: "Slow breathing — the strongest science",
                            icon: "lungs.fill",
                            body: "The breathing patterns are the best-evidenced part of this app. Slow breathing around 5.5–6 breaths per minute reliably increases heart-rate variability and vagal tone. Exhale-weighted patterns (4-7-8, extended exhale) shift the nervous system toward rest. The physiological sigh — two stacked inhales and a long exhale — beat mindfulness meditation for improving mood in a 2023 Stanford randomized trial (Balban et al., Cell Reports Medicine)."
                        )

                        section(
                            title: "Solfeggio tones",
                            icon: "music.note",
                            body: "Frequencies like 528 Hz come from a sacred-music tradition, not neuroscience — claims about 'DNA repair' have no scientific basis. We include 528 Hz because a warm, steady tone is a genuinely pleasant anchor for breath-focused meditation, and it's presented as exactly that: a tradition, not a treatment."
                        )

                        section(
                            title: "A note on safety",
                            icon: "heart.text.square",
                            body: "Resonance is a relaxation aid, not a medical device, and isn't a substitute for professional care. Keep the volume comfortable — quiet is more effective than loud. If you have epilepsy or a seizure history, consult a doctor before using rhythmic audio stimulation. Never use entrainment audio while driving."
                        )
                    }
                    .padding(20)
                }
            }
            .navigationTitle("The Science")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
    }

    private func section(title: String, icon: String, body text: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundStyle(.white)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }
}

#Preview {
    ScienceView()
}
