import CoreHaptics
import SwiftUI
import UIKit

/// A continuous haptic that breathes with the flower: it swells as the
/// petals open and softens as they fold, so the body feels the rhythm the
/// eyes see — plus a gentle tap at each phase boundary.
final class BreathHaptics {
    private var engine: CHHapticEngine?
    private var player: CHHapticAdvancedPatternPlayer?
    private var lastIntensity: Double = -1
    private var lastSendTime: TimeInterval = 0
    private(set) var isRunning = false

    func start() {
        guard !isRunning,
              CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            let engine = try CHHapticEngine()
            engine.resetHandler = { [weak self] in
                try? self?.engine?.start()
            }
            try engine.start()

            let event = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.25),
                ],
                relativeTime: 0,
                duration: 86_400 // effectively endless; stopped explicitly
            )
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makeAdvancedPlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)

            self.engine = engine
            self.player = player
            lastIntensity = -1
            isRunning = true
        } catch {
            stop()
        }
    }

    /// Throttled dynamic update; intensity 0…1 follows the flower's bloom.
    func update(intensity: Double, at time: TimeInterval) {
        guard isRunning, let player else { return }
        let value = min(max(intensity, 0), 1)
        guard time - lastSendTime > 0.08,
              abs(value - lastIntensity) > 0.01 || time - lastSendTime > 0.5 else { return }
        lastSendTime = time
        lastIntensity = value
        let parameter = CHHapticDynamicParameter(
            parameterID: .hapticIntensityControl,
            value: Float(value),
            relativeTime: 0
        )
        try? player.sendParameters([parameter], atTime: CHHapticTimeImmediate)
    }

    func stop() {
        try? player?.stop(atTime: CHHapticTimeImmediate)
        engine?.stop()
        player = nil
        engine = nil
        isRunning = false
    }
}

/// The breathing guide: a flower of translucent petals that blooms open on
/// the inhale and folds closed on the exhale, slowly rotating.
///
/// The bloom is computed every frame as a pure function of elapsed time —
/// not animated with timers — so the flower is sample-accurate against the
/// phase durations: a 7-second exhale takes exactly 7 seconds, with no
/// accumulating drift across cycles. The haptic intensity is derived from
/// the same bloom value, so vibration and animation can never disagree.
struct BreathingGuideView: View {
    let pattern: BreathingPattern
    let tint: Color
    let isActive: Bool

    /// Reference point for elapsed time while running; nil when paused.
    @State private var cycleStart: Date?
    /// Elapsed time accumulated up to the last pause.
    @State private var frozenElapsed: Double = 0
    @State private var appearDate = Date()
    @State private var haptics = BreathHaptics()

    private let petalCount = 6
    private let phaseTap = UIImpactFeedbackGenerator(style: .soft)

    private struct PhaseSpan {
        let phase: BreathPhase
        let start: Double
        let startBloom: Double
        let endBloom: Double
    }

    /// Phase timeline with continuous bloom values across boundaries. A
    /// second stacked inhale (physiological sigh) blooms past full.
    private var spans: [PhaseSpan] {
        var result: [PhaseSpan] = []
        var time = 0.0
        var bloom = 0.0
        for phase in pattern.phases {
            let end: Double
            switch phase.kind {
            case .inhale: end = bloom >= 0.95 ? 1.12 : 1.0
            case .exhale: end = 0
            case .hold: end = bloom
            }
            result.append(PhaseSpan(phase: phase, start: time, startBloom: bloom, endBloom: end))
            time += phase.seconds
            bloom = end
        }
        return result
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = currentElapsed(at: timeline.date)
            let now = state(at: elapsed)
            let rotation = timeline.date.timeIntervalSince(appearDate) * (360.0 / 140.0)

            VStack(spacing: 28) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.08))
                        .frame(width: 300, height: 300)
                        .scaleEffect(0.85 + now.bloom * 0.18)

                    Circle()
                        .strokeBorder(tint.opacity(0.30), lineWidth: 1)
                        .frame(width: 270, height: 270)
                        .scaleEffect(0.85 + now.bloom * 0.15)

                    flower(bloom: now.bloom)
                        .rotationEffect(.degrees(rotation))
                        .scaleEffect(0.78 + now.bloom * 0.26)
                        .shadow(color: tint.opacity(0.40), radius: 36)
                }
                .frame(width: 310, height: 310)
                .opacity(isActive ? 1 : 0.7)

                VStack(spacing: 4) {
                    Text(isActive ? now.label : "Paused")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("\(now.secondsLeft)")
                        .font(.system(.title3, design: .rounded).weight(.medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .monospacedDigit()
                        .opacity(isActive ? 1 : 0)
                }
            }
            .onChange(of: now.phaseIndex) { _, _ in
                if isActive { phaseTap.impactOccurred(intensity: 0.6) }
            }
            .onChange(of: hapticIntensity(for: now, active: isActive)) { _, intensity in
                haptics.update(
                    intensity: intensity,
                    at: timeline.date.timeIntervalSinceReferenceDate
                )
            }
        }
        .onChange(of: isActive) { _, active in
            if active {
                cycleStart = Date().addingTimeInterval(-frozenElapsed)
                haptics.start()
            } else {
                frozenElapsed = currentElapsed(at: Date())
                cycleStart = nil
                haptics.stop()
            }
        }
        .onAppear {
            appearDate = Date()
            if isActive {
                frozenElapsed = 0
                cycleStart = Date()
                haptics.start()
            }
        }
        .onDisappear {
            haptics.stop()
        }
    }

    private func flower(bloom: Double) -> some View {
        ZStack {
            ForEach(0..<petalCount, id: \.self) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [tint.opacity(0.55), tint.opacity(0.20)],
                            center: .center,
                            startRadius: 8,
                            endRadius: 70
                        )
                    )
                    .frame(width: 128, height: 128)
                    .offset(y: -(12 + bloom * 52))
                    .rotationEffect(.degrees(Double(index) * 360.0 / Double(petalCount)))
                    .blendMode(.screen)
            }

            Circle()
                .fill(
                    RadialGradient(
                        colors: [tint.opacity(0.9), tint.opacity(0.3)],
                        center: .center,
                        startRadius: 2,
                        endRadius: 40
                    )
                )
                .frame(width: 72, height: 72)
                .blendMode(.screen)
        }
    }

    private func currentElapsed(at date: Date) -> Double {
        if let cycleStart {
            return date.timeIntervalSince(cycleStart)
        }
        return frozenElapsed
    }

    /// The vibration mirrors the flower: stronger as it blooms, fading as
    /// it folds, a faint presence during holds. Quantized slightly so the
    /// onChange trigger fires at a calm ~haptic-friendly rate.
    private func hapticIntensity(
        for state: (phaseIndex: Int, label: String, secondsLeft: Int, kind: BreathKind, bloom: Double),
        active: Bool
    ) -> Double {
        guard active else { return 0 }
        let raw: Double
        switch state.kind {
        case .inhale, .exhale:
            raw = 0.12 + 0.62 * state.bloom
        case .hold:
            raw = 0.08 + 0.10 * state.bloom
        }
        return (raw * 50).rounded() / 50 // 0.02 steps
    }

    /// Everything the view needs for a given moment, derived exactly from
    /// the phase timeline.
    private func state(at elapsed: Double) -> (
        phaseIndex: Int, label: String, secondsLeft: Int, kind: BreathKind, bloom: Double
    ) {
        let cycle = pattern.cycleSeconds
        guard cycle > 0, let first = spans.first else {
            return (0, "Ready", 0, .hold, 0)
        }
        let position = elapsed.truncatingRemainder(dividingBy: cycle)
        var span = first
        var index = 0
        for (i, candidate) in spans.enumerated() where position >= candidate.start {
            span = candidate
            index = i
        }
        let phaseElapsed = position - span.start
        let progress = min(max(phaseElapsed / span.phase.seconds, 0), 1)
        // Sine ease: gentle at the turn-arounds yet visibly moving through
        // the whole phase, so the motion reads as on-time.
        let eased = 0.5 - 0.5 * cos(.pi * progress)
        let bloom = span.startBloom + (span.endBloom - span.startBloom) * eased
        let secondsLeft = max(1, Int((span.phase.seconds - phaseElapsed).rounded(.up)))
        return (index, span.phase.label, secondsLeft, span.phase.kind, bloom)
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        BreathingGuideView(pattern: .box, tint: .cyan, isActive: true)
    }
}
