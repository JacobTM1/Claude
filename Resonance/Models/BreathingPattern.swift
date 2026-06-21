import Foundation

enum BreathKind {
    case inhale
    case hold
    case exhale
}

struct BreathPhase: Identifiable {
    let id = UUID()
    let kind: BreathKind
    let label: String
    let seconds: Double
}

struct BreathingPattern {
    let name: String
    let summary: String
    let phases: [BreathPhase]

    var cycleSeconds: Double { phases.reduce(0) { $0 + $1.seconds } }

    /// ~5.5 breaths per minute. The best-evidenced pattern here: slow breathing
    /// at this "resonance" rate maximizes heart-rate variability and vagal tone.
    static var coherent: BreathingPattern { BreathingPattern(
        name: L("Coherent Breathing", "Когерентное дыхание"),
        summary: L("In for 5.5s, out for 5.5s — about 5.5 breaths per minute. Shown to maximize heart-rate variability and calm the nervous system.",
                   "Вдох 5,5 с, выдох 5,5 с — около 5,5 вдоха в минуту. Доказано повышает вариабельность сердечного ритма и успокаивает нервную систему."),
        phases: [
            BreathPhase(kind: .inhale, label: L("Breathe In", "Вдох"), seconds: 5.5),
            BreathPhase(kind: .exhale, label: L("Breathe Out", "Выдох"), seconds: 5.5),
        ]
    ) }

    /// Equal four-count phases. Used by Navy SEALs for staying calm and sharp.
    static var box: BreathingPattern { BreathingPattern(
        name: L("Box Breathing", "Квадратное дыхание"),
        summary: L("In 4 · hold 4 · out 4 · hold 4. Steadies attention and keeps arousal level without sedating — ideal for focused work.",
                   "Вдох 4 · задержка 4 · выдох 4 · задержка 4. Удерживает внимание и ровную бодрость без сонливости — идеально для сосредоточенной работы."),
        phases: [
            BreathPhase(kind: .inhale, label: L("Breathe In", "Вдох"), seconds: 4),
            BreathPhase(kind: .hold, label: L("Hold", "Задержка"), seconds: 4),
            BreathPhase(kind: .exhale, label: L("Breathe Out", "Выдох"), seconds: 4),
            BreathPhase(kind: .hold, label: L("Hold", "Задержка"), seconds: 4),
        ]
    ) }

    /// Dr. Andrew Weil's relaxing breath. The long exhale and hold strongly
    /// engage the parasympathetic ("rest and digest") system.
    static var fourSevenEight: BreathingPattern { BreathingPattern(
        name: L("4-7-8 Breathing", "Дыхание 4-7-8"),
        summary: L("In 4 · hold 7 · out 8. The long hold and slow exhale switch the body toward rest — a classic pre-sleep technique.",
                   "Вдох 4 · задержка 7 · выдох 8. Долгая задержка и медленный выдох переключают тело на отдых — классическая техника перед сном."),
        phases: [
            BreathPhase(kind: .inhale, label: L("Breathe In", "Вдох"), seconds: 4),
            BreathPhase(kind: .hold, label: L("Hold", "Задержка"), seconds: 7),
            BreathPhase(kind: .exhale, label: L("Breathe Out", "Выдох"), seconds: 8),
        ]
    ) }

    /// Exhale twice as long as the inhale — the simplest doorway into deep
    /// meditative absorption.
    static var extendedExhale: BreathingPattern { BreathingPattern(
        name: L("Extended Exhale", "Удлинённый выдох"),
        summary: L("In 4 · hold 2 · out 8. Exhaling twice as long as you inhale slows the heart and deepens absorption.",
                   "Вдох 4 · задержка 2 · выдох 8. Выдох вдвое длиннее вдоха замедляет сердце и углубляет погружение."),
        phases: [
            BreathPhase(kind: .inhale, label: L("Breathe In", "Вдох"), seconds: 4),
            BreathPhase(kind: .hold, label: L("Hold", "Задержка"), seconds: 2),
            BreathPhase(kind: .exhale, label: L("Breathe Out", "Выдох"), seconds: 8),
        ]
    ) }

    /// The "physiological sigh" (cyclic sighing) — two stacked inhales and a
    /// long exhale. In a 2023 Stanford trial it outperformed mindfulness
    /// meditation for rapidly improving mood and lowering anxiety.
    static var physiologicalSigh: BreathingPattern { BreathingPattern(
        name: L("Physiological Sigh", "Физиологический вздох"),
        summary: L("Two stacked inhales, then a long sighing exhale. The fastest known way to down-shift the nervous system in real time.",
                   "Два вдоха подряд, затем долгий выдох со вздохом. Самый быстрый известный способ успокоить нервную систему в реальном времени."),
        phases: [
            BreathPhase(kind: .inhale, label: L("Breathe In", "Вдох"), seconds: 2.5),
            BreathPhase(kind: .inhale, label: L("Sip In More", "Доберите воздух"), seconds: 1.5),
            BreathPhase(kind: .exhale, label: L("Sigh It Out", "Выдохните со вздохом"), seconds: 7),
        ]
    ) }

    /// Gentle ocean rhythm with a slightly longer exhale — soft and sustainable.
    static var oceanBreath: BreathingPattern { BreathingPattern(
        name: L("Ocean Breath", "Океанское дыхание"),
        summary: L("In 4 · out 6. A gentle wave-like rhythm with a longer exhale — soft enough to sustain for a whole session.",
                   "Вдох 4 · выдох 6. Мягкий волнообразный ритм с удлинённым выдохом — достаточно лёгкий, чтобы держать его всю сессию."),
        phases: [
            BreathPhase(kind: .inhale, label: L("Breathe In", "Вдох"), seconds: 4),
            BreathPhase(kind: .exhale, label: L("Breathe Out", "Выдох"), seconds: 6),
        ]
    ) }
}
