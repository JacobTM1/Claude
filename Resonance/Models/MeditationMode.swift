import SwiftUI

/// A meditation preset: a tone configuration (binaural beat or pure tone),
/// a matched breathing pattern, and step-by-step guidance.
///
/// Frequencies follow the conventions used in the entrainment literature:
/// the *beat* frequency targets an EEG band (delta/theta/alpha/gamma) while
/// the *carrier* stays in the 150–250 Hz range where binaural beats are
/// perceived most clearly.
struct MeditationMode: Identifiable {
    let name: String
    let tagline: String
    let icon: String
    let colors: [Color]

    /// Base tone in Hz. With a binaural beat, the left ear hears the carrier
    /// and the right ear hears carrier + beat.
    let carrierHz: Double
    /// Difference between ears in Hz. 0 means a pure (non-binaural) tone.
    let beatHz: Double
    let bandLabel: String

    let breathing: BreathingPattern
    let guidance: [String]
    let science: String

    var id: String { name }
    var isPureTone: Bool { beatHz == 0 }

    var frequencyDescription: String {
        if isPureTone {
            return "\(Int(carrierHz)) Hz pure tone · both ears"
        }
        return "\(Int(carrierHz)) Hz left · \(Int(carrierHz + beatHz)) Hz right"
    }

    static let all: [MeditationMode] = [
        MeditationMode(
            name: "Deep Meditation",
            tagline: "Sink beneath the surface of thought",
            icon: "sparkles",
            colors: [.indigo, .purple],
            carrierHz: 200,
            beatHz: 6,
            bandLabel: "Theta · 6 Hz",
            breathing: .extendedExhale,
            guidance: [
                "Put on headphones — binaural beats only work with stereo separation.",
                "Sit with your spine tall, hands resting on your thighs, eyes closed.",
                "Follow the circle: in for 4, hold for 2, out for a long 8.",
                "When thoughts arise, don't fight them — return to the breath and the tone.",
                "After a few minutes, let the counting dissolve and rest in the rhythm.",
            ],
            science: "Theta waves (4–8 Hz) dominate EEG readings of experienced meditators in deep absorption. A 6 Hz binaural beat invites the brain toward that band; the extended exhale slows the heart to meet it."
        ),
        MeditationMode(
            name: "Focus & Clarity",
            tagline: "Sharpen attention for deep work",
            icon: "scope",
            colors: [.cyan, .blue],
            carrierHz: 240,
            beatHz: 40,
            bandLabel: "Gamma · 40 Hz",
            breathing: .box,
            guidance: [
                "Put on headphones and sit upright at your desk or cushion.",
                "Run a few rounds of box breathing: in 4, hold 4, out 4, hold 4.",
                "Pick one task or one point of focus before you begin.",
                "When attention drifts, use the next inhale to bring it back.",
            ],
            science: "Gamma activity around 40 Hz is linked to attention, working memory and sensory binding, and 40 Hz stimulation is actively studied (including at MIT) for its cognitive effects. Box breathing keeps arousal steady without sedation."
        ),
        MeditationMode(
            name: "Calm & De-stress",
            tagline: "Unwind the day in ten minutes",
            icon: "leaf.fill",
            colors: [.teal, .green],
            carrierHz: 220,
            beatHz: 10,
            bandLabel: "Alpha · 10 Hz",
            breathing: .coherent,
            guidance: [
                "Headphones on, shoulders down, jaw unclenched.",
                "Breathe with the circle: 5.5 seconds in, 5.5 seconds out.",
                "Let the exhale fall out of you rather than pushing it.",
                "Scan from forehead to feet, releasing one area per breath.",
            ],
            science: "Alpha waves (8–12 Hz) mark relaxed, wakeful calm — what you feel when you close your eyes and let go. Coherent breathing at ~5.5 breaths/minute is the best-evidenced element in this app: it measurably raises heart-rate variability and vagal tone."
        ),
        MeditationMode(
            name: "Deep Sleep",
            tagline: "Drift down into slow waves",
            icon: "moon.stars.fill",
            colors: [.blue, .indigo],
            carrierHz: 150,
            beatHz: 2.5,
            bandLabel: "Delta · 2.5 Hz",
            breathing: .fourSevenEight,
            guidance: [
                "Lie down in the dark. Earbuds work better than over-ears here.",
                "Begin 4-7-8 breathing: in 4, hold 7, out slowly for 8.",
                "After four rounds, breathe naturally and just listen.",
                "Set the session to end on its own — the tone fades out gently.",
            ],
            science: "Delta waves (0.5–4 Hz) define deep, dreamless slow-wave sleep. A low 150 Hz carrier with a 2.5 Hz beat gives the brain a slow rhythm to settle toward, while 4-7-8 breathing engages the parasympathetic system."
        ),
        MeditationMode(
            name: "Anxiety Release",
            tagline: "Down-shift a racing mind, fast",
            icon: "wind",
            colors: [.mint, .teal],
            carrierHz: 210,
            beatHz: 8,
            bandLabel: "Alpha–Theta · 8 Hz",
            breathing: .physiologicalSigh,
            guidance: [
                "You can do this anywhere — seated, standing, even walking.",
                "Inhale through the nose, then sip in a little more air on top.",
                "Sigh the whole breath out slowly through the mouth.",
                "Five minutes of cycles is usually enough to feel the shift.",
            ],
            science: "The physiological sigh is the standout here: in a 2023 Stanford randomized trial (Balban et al., Cell Reports Medicine), five minutes of cyclic sighing beat mindfulness meditation for improving mood and reducing anxious arousal. The 8 Hz tone sits at the calm alpha–theta border."
        ),
        MeditationMode(
            name: "Healing Tone",
            tagline: "The classic 528 Hz solfeggio",
            icon: "heart.fill",
            colors: [.pink, .orange],
            carrierHz: 528,
            beatHz: 0,
            bandLabel: "Solfeggio · 528 Hz",
            breathing: .oceanBreath,
            guidance: [
                "No headphones needed — a pure tone works on speakers too.",
                "Rest a hand on your chest and feel it rise and fall.",
                "Breathe in for 4, out for 6, like slow waves on a shore.",
                "Let the single unwavering tone be your anchor.",
            ],
            science: "528 Hz is the best known of the solfeggio frequencies, a tradition from sacred music rather than neuroscience — the evidence is anecdotal plus a few small studies. Many people simply find a warm, steady tone deeply soothing, and the slow exhale-weighted breathing does the physiological work."
        ),
    ]
}
