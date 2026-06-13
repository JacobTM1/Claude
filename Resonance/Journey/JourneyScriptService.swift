import Foundation

/// Builds the full ordered script for a journey and scales the silences so
/// the session lands near the chosen length.
///
/// By default it composes the hand-written, safety-reviewed offline scripts,
/// so the experience works with no network and no API key. An adaptive LLM
/// layer can be enabled in Settings; when on, `fetchAdaptiveScript` is the
/// single place to wire a real model call. It always falls back to the
/// offline script on any failure, so the journey can never break.
enum JourneyScriptService {

    /// Composes the offline script: shared intro/induction/deepening, the
    /// theme's journey lines, then shared integration/return/reflection.
    static func offlineScript(for theme: JourneyTheme, minutes: Int) -> [ScriptLine] {
        let lines = JourneyScripts.intro
            + JourneyScripts.induction
            + JourneyScripts.deepening
            + theme.journeyLines
            + JourneyScripts.integration
            + JourneyScripts.returning
            + JourneyScripts.reflection
        return scalePauses(lines, toMinutes: minutes)
    }

    /// Scales the silences between lines so the total spoken-plus-silence
    /// duration approaches the requested length. Grounding (RETURN) pauses
    /// are left mostly intact so coming back never feels rushed.
    private static func scalePauses(_ lines: [ScriptLine], toMinutes minutes: Int) -> [ScriptLine] {
        let target = Double(minutes * 60)
        // Rough estimate of speaking time at the slow guiding rate.
        let speakingEstimate = lines.reduce(0.0) { $0 + Double($1.text.count) * 0.07 }
        let basePause = lines.reduce(0.0) { $0 + Double($1.pauseMs) / 1000.0 }
        let remaining = max(target - speakingEstimate, basePause * 0.6)
        let factor = max(0.6, min(1.8, remaining / max(basePause, 1)))

        return lines.map { line in
            // Don't stretch grounding pauses much — returning stays prompt.
            let f = line.phase.isGrounding ? min(factor, 1.1) : factor
            return ScriptLine(phase: line.phase, text: line.text, pauseMs: Int(Double(line.pauseMs) * f))
        }
    }

    // MARK: - Adaptive (LLM) layer — optional, off by default

    /// System prompt that hard-enforces the framing and wellbeing rules. Any
    /// real model call MUST send this as the system message.
    static let safetySystemPrompt = """
    You write scripts for a calming, guided inner-visualization audio experience \
    called "Journey of Souls". This is contemplative imagery and reflection only.

    HARD RULES — never violate:
    • Never claim to retrieve real past lives, memories, or any afterlife record. \
    Frame everything as inner imagery and reflection: "imagine", "you may notice", \
    "perhaps", "if it feels right".
    • Never implant specific memories or events as fact. Use open, non-leading \
    prompts and always offer the option of noticing nothing ("...or you may not — \
    both are completely fine").
    • Never give medical, psychological, diagnostic, or treatment advice. This is \
    not therapy and not a substitute for care.
    • Keep a warm, slow, unhurried tone. Short sentences. Generous silences.
    • Always keep the user safe and in control; never deepen without offering an \
    easy way back.

    Return ONLY JSON: an array of objects {"phase": <one of intro|induction|\
    deepening|journey|integration|returning|reflection>, "line": <string>, \
    "pauseMs": <integer 3000-12000>}. The array MUST include a full "returning" \
    grounding sequence near the end so the listener is always brought back.
    """

    /// Placeholder for the adaptive call. Wire a real LLM here when ready.
    /// Returns nil so callers transparently fall back to the offline script.
    ///
    /// - Important: Do not embed an API key in the shipped app. Route this
    ///   through a small backend proxy that holds the key, then parse its
    ///   JSON response into `[ScriptLine]`.
    static func fetchAdaptiveScript(
        theme: JourneyTheme,
        minutes: Int,
        reflection: String?
    ) async -> [ScriptLine]? {
        // TODO: POST { system: safetySystemPrompt, theme, minutes, reflection }
        // to the Resonance scripting proxy and decode the returned JSON into
        // [ScriptLine]. Until that endpoint exists, return nil to use offline.
        return nil
    }

    /// The script the session should use, honoring the adaptive toggle and
    /// always falling back to offline content.
    static func resolveScript(
        for theme: JourneyTheme,
        minutes: Int,
        adaptiveEnabled: Bool,
        reflection: String?
    ) async -> [ScriptLine] {
        if adaptiveEnabled,
           let adaptive = await fetchAdaptiveScript(theme: theme, minutes: minutes, reflection: reflection),
           adaptive.contains(where: { $0.phase == .returning }) {
            return adaptive
        }
        return offlineScript(for: theme, minutes: minutes)
    }
}
