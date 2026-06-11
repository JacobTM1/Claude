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
    static let coherent = BreathingPattern(
        name: "Coherent Breathing",
        summary: "In for 5.5s, out for 5.5s — about 5.5 breaths per minute. Shown to maximize heart-rate variability and calm the nervous system.",
        phases: [
            BreathPhase(kind: .inhale, label: "Breathe In", seconds: 5.5),
            BreathPhase(kind: .exhale, label: "Breathe Out", seconds: 5.5),
        ]
    )

    /// Equal four-count phases. Used by Navy SEALs for staying calm and sharp.
    static let box = BreathingPattern(
        name: "Box Breathing",
        summary: "In 4 · hold 4 · out 4 · hold 4. Steadies attention and keeps arousal level without sedating — ideal for focused work.",
        phases: [
            BreathPhase(kind: .inhale, label: "Breathe In", seconds: 4),
            BreathPhase(kind: .hold, label: "Hold", seconds: 4),
            BreathPhase(kind: .exhale, label: "Breathe Out", seconds: 4),
            BreathPhase(kind: .hold, label: "Hold", seconds: 4),
        ]
    )

    /// Dr. Andrew Weil's relaxing breath. The long exhale and hold strongly
    /// engage the parasympathetic ("rest and digest") system.
    static let fourSevenEight = BreathingPattern(
        name: "4-7-8 Breathing",
        summary: "In 4 · hold 7 · out 8. The long hold and slow exhale switch the body toward rest — a classic pre-sleep technique.",
        phases: [
            BreathPhase(kind: .inhale, label: "Breathe In", seconds: 4),
            BreathPhase(kind: .hold, label: "Hold", seconds: 7),
            BreathPhase(kind: .exhale, label: "Breathe Out", seconds: 8),
        ]
    )

    /// Exhale twice as long as the inhale — the simplest doorway into deep
    /// meditative absorption.
    static let extendedExhale = BreathingPattern(
        name: "Extended Exhale",
        summary: "In 4 · hold 2 · out 8. Exhaling twice as long as you inhale slows the heart and deepens absorption.",
        phases: [
            BreathPhase(kind: .inhale, label: "Breathe In", seconds: 4),
            BreathPhase(kind: .hold, label: "Hold", seconds: 2),
            BreathPhase(kind: .exhale, label: "Breathe Out", seconds: 8),
        ]
    )

    /// The "physiological sigh" (cyclic sighing) — two stacked inhales and a
    /// long exhale. In a 2023 Stanford trial it outperformed mindfulness
    /// meditation for rapidly improving mood and lowering anxiety.
    static let physiologicalSigh = BreathingPattern(
        name: "Physiological Sigh",
        summary: "Two stacked inhales, then a long sighing exhale. The fastest known way to down-shift the nervous system in real time.",
        phases: [
            BreathPhase(kind: .inhale, label: "Breathe In", seconds: 2.5),
            BreathPhase(kind: .inhale, label: "Sip In More", seconds: 1.5),
            BreathPhase(kind: .exhale, label: "Sigh It Out", seconds: 7),
        ]
    )

    /// Gentle ocean rhythm with a slightly longer exhale — soft and sustainable.
    static let oceanBreath = BreathingPattern(
        name: "Ocean Breath",
        summary: "In 4 · out 6. A gentle wave-like rhythm with a longer exhale — soft enough to sustain for a whole session.",
        phases: [
            BreathPhase(kind: .inhale, label: "Breathe In", seconds: 4),
            BreathPhase(kind: .exhale, label: "Breathe Out", seconds: 6),
        ]
    )
}
