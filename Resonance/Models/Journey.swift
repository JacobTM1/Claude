import SwiftUI

/// The phases of a Journey of Souls session. The order here is also the
/// progression order; RETURN (grounding) always precedes REFLECTION and can
/// never be skipped, so a session never ends in a deep state.
enum JourneyPhase: Int, CaseIterable, Identifiable {
    case intro
    case induction
    case deepening
    case journey
    case integration
    case returning
    case reflection

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .intro: "Settling In"
        case .induction: "Relaxing"
        case .deepening: "Going Deeper"
        case .journey: "The Journey"
        case .integration: "Resting With It"
        case .returning: "Coming Back"
        case .reflection: "Reflection"
        }
    }

    /// Phases that are part of the gentle grounding sequence — used when the
    /// user taps "Bring me back" so we resume from the right place.
    var isGrounding: Bool { self == .returning || self == .reflection }
}

/// One spoken beat of a journey: a line, the phase it belongs to, and how
/// long to rest in silence afterward. Silence is part of the induction.
struct ScriptLine: Identifiable {
    let id = UUID()
    let phase: JourneyPhase
    let text: String
    /// Pause after the line is spoken, in milliseconds (before scaling).
    let pauseMs: Int
}

/// A journey intention. Names are evocative but non-claiming — this is inner
/// imagery and reflection, never a factual record of anything.
struct JourneyTheme: Identifiable {
    let id: String
    let name: String
    let tagline: String
    let icon: String
    let colors: [Color]
    /// Ambient bed from the existing engine that plays under the voice.
    let ambient: AmbientSound
    /// A low, slow binaural carrier/beat for the bed (theta/delta range).
    let carrierHz: Double
    let beatHz: Double
    /// The theme-specific GUIDED JOURNEY lines. Induction, deepening, return
    /// and reflection are shared (see JourneyScripts) so grounding is always
    /// consistent and safe.
    let journeyLines: [ScriptLine]

    static let all: [JourneyTheme] = [
        JourneyTheme(
            id: "calmer-self",
            name: "Meet a Calmer Self",
            tagline: "Imagine a steadier version of you",
            icon: "person.fill.viewfinder",
            colors: [Color(red: 0.30, green: 0.34, blue: 0.78), Color(red: 0.16, green: 0.18, blue: 0.42)],
            ambient: .wind,
            carrierHz: 150,
            beatHz: 4,
            journeyLines: [
                ScriptLine(phase: .journey, text: "In this quiet place, imagine that somewhere ahead of you there is a calmer version of yourself.", pauseMs: 7000),
                ScriptLine(phase: .journey, text: "You don't have to force any picture. You may sense a presence, a feeling, a warmth — or simply the idea of them. All of that is fine.", pauseMs: 8000),
                ScriptLine(phase: .journey, text: "Notice how this calmer self carries themselves. Unhurried. At ease. Nothing to prove.", pauseMs: 9000),
                ScriptLine(phase: .journey, text: "If it feels right, let yourself move a little closer. And if it doesn't, you can simply observe from here.", pauseMs: 8000),
                ScriptLine(phase: .journey, text: "You might wonder what this calmer self already knows that you are still learning. Let any answer arise on its own — or let the question simply rest.", pauseMs: 10000),
                ScriptLine(phase: .journey, text: "Take whatever sense of steadiness is here, and let it settle somewhere in your body. Perhaps the chest. Perhaps the breath.", pauseMs: 9000),
            ]
        ),
        JourneyTheme(
            id: "release-weight",
            name: "Release a Weight",
            tagline: "Set something down, gently",
            icon: "wind",
            colors: [Color(red: 0.20, green: 0.42, blue: 0.52), Color(red: 0.10, green: 0.20, blue: 0.30)],
            ambient: .ocean,
            carrierHz: 160,
            beatHz: 3,
            journeyLines: [
                ScriptLine(phase: .journey, text: "Let your attention rest on the sense that you may have been carrying something heavier than you need to.", pauseMs: 8000),
                ScriptLine(phase: .journey, text: "You don't need to name it or explain it. Just notice that it has a weight, and that you are allowed to set it down for a while.", pauseMs: 9000),
                ScriptLine(phase: .journey, text: "Imagine that weight taking some simple form in your hands — a stone, a parcel, a shape of your own choosing.", pauseMs: 9000),
                ScriptLine(phase: .journey, text: "When you are ready — and only when you are ready — imagine placing it down on the ground in front of you.", pauseMs: 10000),
                ScriptLine(phase: .journey, text: "You can always pick it back up later if you wish. For now, notice how your hands feel a little lighter, a little more open.", pauseMs: 9000),
                ScriptLine(phase: .journey, text: "Let that lightness move up through your arms, your shoulders, softening as it goes.", pauseMs: 9000),
            ]
        ),
        JourneyTheme(
            id: "journey-inward",
            name: "A Journey Inward",
            tagline: "Follow a quiet path within",
            icon: "sparkles",
            colors: [Color(red: 0.36, green: 0.24, blue: 0.62), Color(red: 0.16, green: 0.10, blue: 0.34)],
            ambient: .rain,
            carrierHz: 140,
            beatHz: 4,
            journeyLines: [
                ScriptLine(phase: .journey, text: "Imagine a soft path opening in front of you, leading gently inward, lit just enough to feel safe.", pauseMs: 8000),
                ScriptLine(phase: .journey, text: "With each step, you move a little further from the noise of the day and a little closer to something quiet at your center.", pauseMs: 10000),
                ScriptLine(phase: .journey, text: "You may notice images, colours, memories, or nothing in particular. Whatever comes, you can let it pass through without holding on.", pauseMs: 10000),
                ScriptLine(phase: .journey, text: "Ahead, the path opens into a still, open space that belongs only to you. Step into it in your own time.", pauseMs: 10000),
                ScriptLine(phase: .journey, text: "Rest here. There is nothing to find and nothing to fix. Simply be in this quiet for a few breaths.", pauseMs: 12000),
                ScriptLine(phase: .journey, text: "Whatever stillness you've touched here is always yours. You can return to it whenever you choose.", pauseMs: 9000),
            ]
        ),
        JourneyTheme(
            id: "peaceful-place",
            name: "Visit a Peaceful Place",
            tagline: "Rest somewhere calm in your mind",
            icon: "moon.stars.fill",
            colors: [Color(red: 0.18, green: 0.28, blue: 0.55), Color(red: 0.08, green: 0.12, blue: 0.30)],
            ambient: .ocean,
            carrierHz: 150,
            beatHz: 3,
            journeyLines: [
                ScriptLine(phase: .journey, text: "Let a peaceful place begin to form in your mind. Somewhere real or imagined, where you feel completely at ease.", pauseMs: 9000),
                ScriptLine(phase: .journey, text: "Notice what is around you here. The light. The temperature of the air. Any gentle sounds.", pauseMs: 10000),
                ScriptLine(phase: .journey, text: "There is nowhere you need to be and nothing you need to do. This place asks nothing of you.", pauseMs: 9000),
                ScriptLine(phase: .journey, text: "Find a comfortable spot to settle, and let your body feel held by this place.", pauseMs: 10000),
                ScriptLine(phase: .journey, text: "Breathe in the calm of it. Let it fill the spaces that have felt tight or tired.", pauseMs: 11000),
                ScriptLine(phase: .journey, text: "Know that this place remains within you. You carry it wherever you go.", pauseMs: 9000),
            ]
        ),
    ]
}
