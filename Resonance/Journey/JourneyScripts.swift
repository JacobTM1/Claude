import Foundation

/// Shared, hand-written script segments used by every journey. Keeping
/// induction, deepening, integration, return and reflection in one place
/// means the grounding sequence is always consistent and safe, regardless
/// of theme or of whether adaptive content is enabled.
enum JourneyScripts {

    static let intro: [ScriptLine] = [
        ScriptLine(phase: .intro, text: "Welcome. Find a position where you can be still and supported, seated or lying down.", pauseMs: 6000),
        ScriptLine(phase: .intro, text: "There is nothing you need to make happen here. You can simply let this unfold.", pauseMs: 6000),
        ScriptLine(phase: .intro, text: "Whenever you feel ready, gently let your eyes close.", pauseMs: 7000),
    ]

    static let induction: [ScriptLine] = [
        ScriptLine(phase: .induction, text: "Begin to notice your breath, without changing it. Just following it in, and out.", pauseMs: 9000),
        ScriptLine(phase: .induction, text: "With each breath out, allow your body to soften a little more into whatever is supporting you.", pauseMs: 10000),
        ScriptLine(phase: .induction, text: "Let your shoulders drop. Let your jaw loosen. Let the small muscles around your eyes rest.", pauseMs: 10000),
        ScriptLine(phase: .induction, text: "There is no right way to feel. Whatever is here is welcome.", pauseMs: 9000),
    ]

    static let deepening: [ScriptLine] = [
        ScriptLine(phase: .deepening, text: "In a moment I'll count down from five. With each number, you can let yourself settle a little deeper into calm.", pauseMs: 7000),
        ScriptLine(phase: .deepening, text: "Five. Softening.", pauseMs: 7000),
        ScriptLine(phase: .deepening, text: "Four. Heavier, and at ease.", pauseMs: 7000),
        ScriptLine(phase: .deepening, text: "Three. Quieter inside.", pauseMs: 8000),
        ScriptLine(phase: .deepening, text: "Two. Drifting gently inward.", pauseMs: 8000),
        ScriptLine(phase: .deepening, text: "One. Calm, and aware, and completely safe.", pauseMs: 9000),
    ]

    static let integration: [ScriptLine] = [
        ScriptLine(phase: .integration, text: "Let whatever you noticed simply rest with you now. You don't need to analyse it or hold on to it.", pauseMs: 10000),
        ScriptLine(phase: .integration, text: "If anything felt meaningful, you can let it settle quietly. If nothing did, that is just as well.", pauseMs: 10000),
        ScriptLine(phase: .integration, text: "Take a slow breath, and let this experience be exactly what it was.", pauseMs: 9000),
    ]

    /// RETURN — the grounding sequence. This always runs before a session is
    /// considered complete, and is what the "Bring me back" control triggers.
    static let returning: [ScriptLine] = [
        ScriptLine(phase: .returning, text: "It's time to gently come back. Bring your awareness toward the present moment, in your own time.", pauseMs: 7000),
        ScriptLine(phase: .returning, text: "Begin to notice the surface beneath you, and the weight of your body resting on it.", pauseMs: 7000),
        ScriptLine(phase: .returning, text: "I'll count up from one to five. With each number, become a little more awake and present.", pauseMs: 5000),
        ScriptLine(phase: .returning, text: "One. Awareness returning to your body.", pauseMs: 4000),
        ScriptLine(phase: .returning, text: "Two. Feeling the air around you.", pauseMs: 4000),
        ScriptLine(phase: .returning, text: "Three. Gently wiggle your fingers and your toes.", pauseMs: 4500),
        ScriptLine(phase: .returning, text: "Four. Taking a fuller breath, energy returning.", pauseMs: 4500),
        ScriptLine(phase: .returning, text: "Five. When you're ready, and only when you're ready, let your eyes open.", pauseMs: 5000),
    ]

    static let reflection: [ScriptLine] = [
        ScriptLine(phase: .reflection, text: "Take a moment before moving on. Notice how you feel now, compared to when you began.", pauseMs: 5000),
    ]

    /// An abbreviated grounding used when the user exits early — shorter, but
    /// it still brings them all the way back. Never an abrupt stop.
    static let quickReturn: [ScriptLine] = [
        ScriptLine(phase: .returning, text: "Of course. Let's gently bring you back now.", pauseMs: 4000),
        ScriptLine(phase: .returning, text: "Feel the surface beneath you, and the weight of your body resting on it.", pauseMs: 5000),
        ScriptLine(phase: .returning, text: "Take a fuller breath, and let a little energy return.", pauseMs: 4500),
        ScriptLine(phase: .returning, text: "Wiggle your fingers and your toes. Becoming present and awake.", pauseMs: 4500),
        ScriptLine(phase: .returning, text: "When you're ready, let your eyes open. Welcome back.", pauseMs: 4000),
    ]
}
