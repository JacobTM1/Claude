import SwiftUI

/// A meditation preset: a tone configuration (binaural beat or pure tone),
/// a matched breathing pattern, and step-by-step guidance.
///
/// Frequencies follow the conventions used in the entrainment literature:
/// the *beat* frequency targets an EEG band (delta/theta/alpha/gamma) while
/// the *carrier* stays in the 150–250 Hz range where binaural beats are
/// perceived most clearly.
struct MeditationMode: Identifiable {
    /// Stable, language-independent identifier used for routing and lookup.
    let key: String
    let name: String
    let tagline: String
    /// Mode-specific posture cue shown during the pre-session countdown.
    let settleText: String
    let icon: String
    let colors: [Color]

    /// Base tone in Hz. With a binaural beat, the left ear hears the carrier
    /// and the right ear hears carrier + beat.
    let carrierHz: Double
    /// Difference between ears in Hz. 0 means a pure (non-binaural) tone.
    let beatHz: Double
    let bandLabel: String

    let breathing: BreathingPattern
    /// How the energy particles move during this mode's session.
    let particleMotion: ParticleMotion
    let guidance: [String]
    let science: String

    var id: String { key }
    var isPureTone: Bool { beatHz == 0 }

    var frequencyDescription: String {
        if isPureTone {
            return "\(Int(carrierHz)) Hz " + L("pure tone · both ears", "чистый тон · оба уха")
        }
        return "\(Int(carrierHz)) Hz " + L("left", "лев.") + " · \(Int(carrierHz + beatHz)) Hz " + L("right", "прав.")
    }

    /// Recomputed on access so the current language is always reflected.
    static var all: [MeditationMode] { buildAll() }

    private static func buildAll() -> [MeditationMode] { [
        MeditationMode(
            key: "deep-meditation",
            name: L("Deep Meditation", "Глубокая медитация"),
            tagline: L("Sink beneath the surface of thought", "Опустись глубже потока мыслей"),
            settleText: L("Sit tall, rest your hands on your thighs,\nand let your eyes close.",
                          "Сядьте прямо, положите руки на бёдра\nи закройте глаза."),
            icon: "sparkles",
            colors: [.indigo, .purple],
            carrierHz: 200,
            beatHz: 6,
            bandLabel: L("Theta · 6 Hz", "Тета · 6 Гц"),
            breathing: .extendedExhale,
            particleMotion: .rise,
            guidance: L(
                [
                    "Put on headphones — binaural beats only work with stereo separation.",
                    "Sit with your spine tall, hands resting on your thighs, eyes closed.",
                    "Follow the circle: in for 4, hold for 2, out for a long 8.",
                    "Watch the rising lights: imagine energy drawn up from the base of your spine to the crown of your head.",
                    "When thoughts arise, don't fight them — return to the breath and the rising energy.",
                    "After a few minutes, let the counting dissolve and rest in the rhythm.",
                ],
                [
                    "Наденьте наушники — бинауральные ритмы работают только при стереоразделении.",
                    "Сядьте с прямой спиной, руки на бёдрах, глаза закрыты.",
                    "Следуйте за кругом: вдох на 4, задержка на 2, долгий выдох на 8.",
                    "Наблюдайте за восходящими огнями: представьте, как энергия поднимается от основания позвоночника к макушке.",
                    "Когда приходят мысли, не боритесь с ними — вернитесь к дыханию и восходящей энергии.",
                    "Через несколько минут отпустите счёт и растворитесь в ритме.",
                ]
            ),
            science: L(
                "Theta waves (4–8 Hz) dominate EEG readings of experienced meditators in deep absorption. A 6 Hz binaural beat invites the brain toward that band; the extended exhale slows the heart to meet it.",
                "Тета-волны (4–8 Гц) преобладают на ЭЭГ опытных медитирующих в глубоком погружении. Бинауральный ритм 6 Гц мягко настраивает мозг на этот диапазон, а удлинённый выдох замедляет сердце ему навстречу."
            )
        ),
        MeditationMode(
            key: "focus-clarity",
            name: L("Focus & Clarity", "Фокус и ясность"),
            tagline: L("Sharpen attention for deep work", "Заостри внимание для глубокой работы"),
            settleText: L("Sit upright, take one decisive breath,\nand choose your single point of focus.",
                          "Сядьте прямо, сделайте один решительный вдох\nи выберите единственную точку внимания."),
            icon: "scope",
            colors: [.cyan, .blue],
            carrierHz: 240,
            beatHz: 40,
            bandLabel: L("Gamma · 40 Hz", "Гамма · 40 Гц"),
            breathing: .box,
            particleMotion: .orbit,
            guidance: L(
                [
                    "Put on headphones and sit upright at your desk or cushion.",
                    "Run a few rounds of box breathing: in 4, hold 4, out 4, hold 4.",
                    "Pick one task or one point of focus before you begin.",
                    "When attention drifts, use the next inhale to bring it back.",
                ],
                [
                    "Наденьте наушники и сядьте прямо за столом или на подушке.",
                    "Сделайте несколько кругов квадратного дыхания: вдох 4, задержка 4, выдох 4, задержка 4.",
                    "Перед началом выберите одну задачу или одну точку внимания.",
                    "Когда внимание уходит, верните его на следующем вдохе.",
                ]
            ),
            science: L(
                "Gamma activity around 40 Hz is linked to attention, working memory and sensory binding, and 40 Hz stimulation is actively studied (including at MIT) for its cognitive effects. Box breathing keeps arousal steady without sedation.",
                "Гамма-активность около 40 Гц связана с вниманием, рабочей памятью и сенсорной интеграцией; стимуляцию на 40 Гц активно изучают (в том числе в MIT) ради её влияния на когнитивные функции. Квадратное дыхание удерживает ровную бодрость без сонливости."
            )
        ),
        MeditationMode(
            key: "calm-destress",
            name: L("Calm & De-stress", "Спокойствие и снятие стресса"),
            tagline: L("Unwind the day in ten minutes", "Отпусти день за десять минут"),
            settleText: L("Drop your shoulders, unclench your jaw,\nand let the chair hold your weight.",
                          "Опустите плечи, расслабьте челюсть\nи позвольте креслу держать ваш вес."),
            icon: "leaf.fill",
            colors: [.teal, .green],
            carrierHz: 220,
            beatHz: 10,
            bandLabel: L("Alpha · 10 Hz", "Альфа · 10 Гц"),
            breathing: .coherent,
            particleMotion: .drift,
            guidance: L(
                [
                    "Headphones on, shoulders down, jaw unclenched.",
                    "Breathe with the circle: 5.5 seconds in, 5.5 seconds out.",
                    "Let the exhale fall out of you rather than pushing it.",
                    "Scan from forehead to feet, releasing one area per breath.",
                ],
                [
                    "Наушники надеты, плечи опущены, челюсть расслаблена.",
                    "Дышите вместе с кругом: 5,5 секунды вдох, 5,5 секунды выдох.",
                    "Пусть выдох выходит сам, не выталкивайте его.",
                    "Пройдите вниманием ото лба к стопам, отпуская по одной зоне на каждом выдохе.",
                ]
            ),
            science: L(
                "Alpha waves (8–12 Hz) mark relaxed, wakeful calm — what you feel when you close your eyes and let go. Coherent breathing at ~5.5 breaths/minute is the best-evidenced element in this app: it measurably raises heart-rate variability and vagal tone.",
                "Альфа-волны (8–12 Гц) — это расслабленное бодрствующее спокойствие, которое вы чувствуете, закрыв глаза и отпустив напряжение. Когерентное дыхание ~5,5 вдоха в минуту — наиболее доказанный элемент приложения: оно измеримо повышает вариабельность сердечного ритма и тонус блуждающего нерва."
            )
        ),
        MeditationMode(
            key: "deep-sleep",
            name: L("Deep Sleep", "Глубокий сон"),
            tagline: L("Drift down into slow waves", "Погрузись в медленные волны"),
            settleText: L("Lie down, let your body get heavy,\nand let the day end here.",
                          "Лягте, дайте телу стать тяжёлым\nи позвольте дню закончиться здесь."),
            icon: "moon.stars.fill",
            colors: [.blue, .indigo],
            carrierHz: 150,
            beatHz: 2.5,
            bandLabel: L("Delta · 2.5 Hz", "Дельта · 2,5 Гц"),
            breathing: .fourSevenEight,
            particleMotion: .fall,
            guidance: L(
                [
                    "Lie down in the dark. Earbuds work better than over-ears here.",
                    "Begin 4-7-8 breathing: in 4, hold 7, out slowly for 8.",
                    "After four rounds, breathe naturally and just listen.",
                    "Set the session to end on its own — the tone fades out gently.",
                ],
                [
                    "Лягте в темноте. Здесь вкладыши подойдут лучше, чем большие наушники.",
                    "Начните дыхание 4-7-8: вдох 4, задержка 7, медленный выдох 8.",
                    "После четырёх кругов дышите естественно и просто слушайте.",
                    "Дайте сессии завершиться самой — тон мягко угаснет.",
                ]
            ),
            science: L(
                "Delta waves (0.5–4 Hz) define deep, dreamless slow-wave sleep. A low 150 Hz carrier with a 2.5 Hz beat gives the brain a slow rhythm to settle toward, while 4-7-8 breathing engages the parasympathetic system.",
                "Дельта-волны (0,5–4 Гц) определяют глубокий сон без сновидений. Низкая несущая 150 Гц с ритмом 2,5 Гц задаёт мозгу медленный ритм для погружения, а дыхание 4-7-8 включает парасимпатическую систему."
            )
        ),
        MeditationMode(
            key: "anxiety-release",
            name: L("Anxiety Release", "Снятие тревоги"),
            tagline: L("Down-shift a racing mind, fast", "Быстро успокой бегущий ум"),
            settleText: L("You are safe. Loosen your grip\nand let the next breath come to you.",
                          "Вы в безопасности. Ослабьте хватку\nи позвольте следующему вдоху прийти к вам."),
            icon: "wind",
            colors: [.mint, .teal],
            carrierHz: 210,
            beatHz: 8,
            bandLabel: L("Alpha–Theta · 8 Hz", "Альфа–Тета · 8 Гц"),
            breathing: .physiologicalSigh,
            particleMotion: .drift,
            guidance: L(
                [
                    "You can do this anywhere — seated, standing, even walking.",
                    "Inhale through the nose, then sip in a little more air on top.",
                    "Sigh the whole breath out slowly through the mouth.",
                    "Five minutes of cycles is usually enough to feel the shift.",
                ],
                [
                    "Это можно делать где угодно — сидя, стоя, даже на ходу.",
                    "Вдохните через нос, затем доберите немного воздуха сверху.",
                    "Медленно выдохните со вздохом через рот.",
                    "Обычно пяти минут циклов достаточно, чтобы почувствовать перемену.",
                ]
            ),
            science: L(
                "The physiological sigh is the standout here: in a 2023 Stanford randomized trial (Balban et al., Cell Reports Medicine), five minutes of cyclic sighing beat mindfulness meditation for improving mood and reducing anxious arousal. The 8 Hz tone sits at the calm alpha–theta border.",
                "Физиологический вздох здесь главное: в рандомизированном исследовании Стэнфорда 2023 года (Balban et al., Cell Reports Medicine) пять минут циклических вздохов превзошли медитацию осознанности по улучшению настроения и снижению тревожного возбуждения. Тон 8 Гц лежит на спокойной границе альфа–тета."
            )
        ),
        MeditationMode(
            key: "healing-tone",
            name: L("Healing Tone", "Целебный тон"),
            tagline: L("The classic 528 Hz solfeggio", "Классическая сольфеджио 528 Гц"),
            settleText: L("Rest a hand on your heart\nand feel it rise and fall.",
                          "Положите руку на сердце\nи почувствуйте, как оно поднимается и опускается."),
            icon: "heart.fill",
            colors: [.pink, .orange],
            carrierHz: 528,
            beatHz: 0,
            bandLabel: L("Solfeggio · 528 Hz", "Сольфеджио · 528 Гц"),
            breathing: .oceanBreath,
            particleMotion: .rise,
            guidance: L(
                [
                    "No headphones needed — a pure tone works on speakers too.",
                    "Rest a hand on your chest and feel it rise and fall.",
                    "Breathe in for 4, out for 6, like slow waves on a shore.",
                    "Let the single unwavering tone be your anchor.",
                ],
                [
                    "Наушники не нужны — чистый тон работает и через динамики.",
                    "Положите руку на грудь и почувствуйте, как она поднимается и опускается.",
                    "Вдох на 4, выдох на 6, как медленные волны у берега.",
                    "Пусть единый ровный тон будет вашим якорем.",
                ]
            ),
            science: L(
                "528 Hz is the best known of the solfeggio frequencies, a tradition from sacred music rather than neuroscience — the evidence is anecdotal plus a few small studies. Many people simply find a warm, steady tone deeply soothing, and the slow exhale-weighted breathing does the physiological work.",
                "528 Гц — самая известная из частот сольфеджио, традиция из сакральной музыки, а не из нейронауки: доказательства анекдотичны плюс несколько небольших исследований. Многим просто кажется тёплый ровный тон глубоко успокаивающим, а основную физиологическую работу делает медленное дыхание с акцентом на выдох."
            )
        ),
    ] }
