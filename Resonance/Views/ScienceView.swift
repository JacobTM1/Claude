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
                            title: L("How Resonance works", "Как работает Resonance"),
                            icon: "waveform.path",
                            body: L("Each session pairs a generated tone with a matched breathing pattern. The tone gives your mind a steady anchor; the breathing does measurable physiological work. Used together for 10–20 minutes, they make it much easier to settle into a meditative state.",
                                    "Каждая сессия сочетает сгенерированный тон с подобранным ритмом дыхания. Тон даёт уму устойчивый якорь, а дыхание делает измеримую физиологическую работу. Вместе за 10–20 минут они помогают намного легче войти в медитативное состояние.")
                        )

                        section(
                            title: L("Binaural beats", "Бинауральные ритмы"),
                            icon: "headphones",
                            body: L("When each ear hears a slightly different frequency (say 200 Hz and 206 Hz), the brain perceives a 6 Hz pulse — the difference. The beat frequency targets an EEG band: delta (0.5–4 Hz) for sleep, theta (4–8 Hz) for deep meditation, alpha (8–12 Hz) for relaxed calm, and gamma (~40 Hz) for attention. A 2019 meta-analysis (Garcia-Argibay et al.) found measurable effects on anxiety, attention and memory, though the research is still young and effects vary by person. Stereo headphones are essential — the effect cannot exist through speakers.",
                                    "Когда каждое ухо слышит слегка разные частоты (скажем, 200 Гц и 206 Гц), мозг воспринимает пульс 6 Гц — их разницу. Частота ритма нацелена на диапазон ЭЭГ: дельта (0,5–4 Гц) для сна, тета (4–8 Гц) для глубокой медитации, альфа (8–12 Гц) для расслабленного спокойствия и гамма (~40 Гц) для внимания. Метаанализ 2019 года (Garcia-Argibay et al.) обнаружил измеримое влияние на тревогу, внимание и память, хотя исследования ещё молоды и эффект различается у разных людей. Стереонаушники обязательны — через динамики эффект невозможен.")
                        )

                        section(
                            title: L("Slow breathing — the strongest science", "Медленное дыхание — самая сильная наука"),
                            icon: "lungs.fill",
                            body: L("The breathing patterns are the best-evidenced part of this app. Slow breathing around 5.5–6 breaths per minute reliably increases heart-rate variability and vagal tone. Exhale-weighted patterns (4-7-8, extended exhale) shift the nervous system toward rest. The physiological sigh — two stacked inhales and a long exhale — beat mindfulness meditation for improving mood in a 2023 Stanford randomized trial (Balban et al., Cell Reports Medicine).",
                                    "Ритмы дыхания — наиболее доказанная часть приложения. Медленное дыхание около 5,5–6 вдохов в минуту надёжно повышает вариабельность сердечного ритма и тонус блуждающего нерва. Техники с акцентом на выдох (4-7-8, удлинённый выдох) переключают нервную систему на отдых. Физиологический вздох — два вдоха подряд и долгий выдох — превзошёл медитацию осознанности по улучшению настроения в рандомизированном исследовании Стэнфорда 2023 года (Balban et al., Cell Reports Medicine).")
                        )

                        section(
                            title: L("Solfeggio tones", "Тоны сольфеджио"),
                            icon: "music.note",
                            body: L("Frequencies like 528 Hz come from a sacred-music tradition, not neuroscience — claims about 'DNA repair' have no scientific basis. We include 528 Hz because a warm, steady tone is a genuinely pleasant anchor for breath-focused meditation, and it's presented as exactly that: a tradition, not a treatment.",
                                    "Частоты вроде 528 Гц происходят из традиции сакральной музыки, а не из нейронауки — у заявлений о «восстановлении ДНК» нет научной основы. Мы включаем 528 Гц, потому что тёплый ровный тон — действительно приятный якорь для медитации на дыхании, и подаём его именно так: как традицию, а не лечение.")
                        )

                        section(
                            title: L("A note on safety", "О безопасности"),
                            icon: "heart.text.square",
                            body: L("Resonance is a relaxation aid, not a medical device, and isn't a substitute for professional care. Keep the volume comfortable — quiet is more effective than loud. If you have epilepsy or a seizure history, consult a doctor before using rhythmic audio stimulation. Never use entrainment audio while driving.",
                                    "Resonance — средство для расслабления, а не медицинский прибор, и не заменяет профессиональную помощь. Держите громкость комфортной — тихое эффективнее громкого. При эпилепсии или судорогах в анамнезе проконсультируйтесь с врачом перед использованием ритмической аудиостимуляции. Никогда не используйте такое аудио за рулём.")
                        )
                    }
                    .padding(20)
                }
            }
            .navigationTitle(L("The Science", "Наука"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L("Done", "Готово")) { dismiss() }
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
