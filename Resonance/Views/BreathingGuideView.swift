import SwiftUI
import UIKit

/// The breathing guide: a flower of translucent petals that blooms open on
/// the inhale and folds closed on the exhale, slowly rotating, with a soft
/// haptic tap at each phase change.
///
/// The bloom is computed every frame as a pure function of elapsed time —
/// not animated with timers — so the flower is sample-accurate against the
/// phase durations: a 7-second exhale takes exactly 7 seconds, with no
/// accumulating drift across cycles.
struct BreathingGuideView: View {
    let pattern: BreathingPattern
    let tint: Color
    let isActive: Bool

    /// Reference point for elapsed time while running; nil when paused.
    @State private var cycleStart: Date?
    /// Elapsed time accumulated up to the last pause.
    @State private var frozenElapsed: Double = 0
    @State private var appearDate = Date()

    private let petalCount = 6
    private let haptic = UIImpactFeedbackGenerator(style: .soft)

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
                if isActive { haptic.impactOccurred() }
            }
        }
        .onChange(of: isActive) { _, active in
            if active {
                cycleStart = Date().addingTimeInterval(-frozenElapsed)
            } else {
                frozenElapsed = currentElapsed(at: Date())
                cycleStart = nil
            }
        }
        .onAppear {
            appearDate = Date()
            if isActive {
                frozenElapsed = 0
                cycleStart = Date()
            }
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

    /// Everything the view needs for a given moment, derived exactly from
    /// the phase timeline.
    private func state(at elapsed: Double) -> (
        phaseIndex: Int, label: String, secondsLeft: Int, bloom: Double
    ) {
        let cycle = pattern.cycleSeconds
        guard cycle > 0, let first = spans.first else {
            return (0, "Ready", 0, 0)
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
        return (index, span.phase.label, secondsLeft, bloom)
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        BreathingGuideView(pattern: .box, tint: .cyan, isActive: true)
    }
}
