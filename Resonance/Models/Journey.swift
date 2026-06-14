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
            id: "meet-your-soul",
            name: "Meet Your Soul",
            tagline: "Sense the part of you beyond this life",
            icon: "sparkles",
            colors: [Color(red: 0.32, green: 0.20, blue: 0.56), Color(red: 0.06, green: 0.04, blue: 0.20)],
            ambient: .wind,
            carrierHz: 140,
            beatHz: 4,
            journeyLines: [
                ScriptLine(phase: .journey, text: "Let your awareness drift inward, far beneath the surface of this ordinary day.", pauseMs: 9000),
                ScriptLine(phase: .journey, text: "Imagine a soft light ahead — the sense of something timeless in you, older than this single life.", pauseMs: 10000),
                ScriptLine(phase: .journey, text: "You may sense a presence, a warmth, a knowing. Or simply the idea of it. All of that is welcome.", pauseMs: 10000),
                ScriptLine(phase: .journey, text: "Rest near this quiet, deeper self. There is nothing to prove here, and nothing to fear.", pauseMs: 11000),
                ScriptLine(phase: .journey, text: "If a feeling or an image wishes to come, let it. If not, the stillness itself is enough.", pauseMs: 11000),
            ]
        ),
        JourneyTheme(
            id: "past-life",
            name: "Explore a Past Life",
            tagline: "Wander into a life that may have been",
            icon: "hourglass",
            colors: [Color(red: 0.20, green: 0.16, blue: 0.48), Color(red: 0.05, green: 0.05, blue: 0.18)],
            ambient: .ocean,
            carrierHz: 150,
            beatHz: 3,
            journeyLines: [
                ScriptLine(phase: .journey, text: "Picture a soft corridor of light stretching back, gently, beyond this lifetime.", pauseMs: 9000),
                ScriptLine(phase: .journey, text: "When you're ready, imagine stepping through — into a scene that simply forms on its own.", pauseMs: 10000),
                ScriptLine(phase: .journey, text: "You may notice ground beneath you, a time, a place, perhaps a figure. Whatever appears is fine; this is imagery, not a fixed record.", pauseMs: 11000),
                ScriptLine(phase: .journey, text: "Move through this life as a calm observer. Notice without needing to explain.", pauseMs: 11000),
                ScriptLine(phase: .journey, text: "Take whatever feeling rises and hold it gently. Then let the scene soften and fade.", pauseMs: 10000),
            ]
        ),
        JourneyTheme(
            id: "meet-a-guide",
            name: "Meet a Guide",
            tagline: "Sense a wise, kind presence",
            icon: "moon.stars.fill",
            colors: [Color(red: 0.16, green: 0.26, blue: 0.52), Color(red: 0.04, green: 0.07, blue: 0.22)],
            ambient: .wind,
            carrierHz: 150,
            beatHz: 4,
            journeyLines: [
                ScriptLine(phase: .journey, text: "Imagine you are not alone in this quiet place — that a kind, wise presence is near.", pauseMs: 10000),
                ScriptLine(phase: .journey, text: "You don't need to see it clearly. A sense, a warmth, a feeling of being accompanied is enough.", pauseMs: 10000),
                ScriptLine(phase: .journey, text: "If there is something you wish to ask, you may. Let any answer arise softly — or let the question simply rest.", pauseMs: 12000),
                ScriptLine(phase: .journey, text: "Feel the steadiness of this presence settle into you, like being gently understood.", pauseMs: 10000),
                ScriptLine(phase: .journey, text: "Know that this calm companionship is something you can return to whenever you choose.", pauseMs: 9000),
            ]
        ),
        JourneyTheme(
            id: "heal-a-wound",
            name: "Heal an Old Wound",
            tagline: "Gently release something you've carried",
            icon: "heart.circle.fill",
            colors: [Color(red: 0.34, green: 0.18, blue: 0.40), Color(red: 0.08, green: 0.05, blue: 0.18)],
            ambient: .ocean,
            carrierHz: 160,
            beatHz: 3,
            journeyLines: [
                ScriptLine(phase: .journey, text: "Let your attention rest on something you may have carried for a long time.", pauseMs: 9000),
                ScriptLine(phase: .journey, text: "You don't need to name it or relive it. Just sense that it has a weight, and that you're safe here.", pauseMs: 10000),
                ScriptLine(phase: .journey, text: "Imagine a gentle light moving toward it — not to force anything, only to soften and warm it.", pauseMs: 11000),
                ScriptLine(phase: .journey, text: "If it feels right, let a little of that weight set itself down. You can always pick it up later.", pauseMs: 11000),
                ScriptLine(phase: .journey, text: "Notice any small sense of lightness, and let it spread, slowly, through you.", pauseMs: 10000),
            ]
        ),
    ]
}
