import SwiftUI
import UIKit

/// The breathing guide: a flower of translucent petals that blooms open on
/// the inhale and folds closed on the exhale, slowly rotating the whole
/// time, with a soft haptic tap at each phase change.
struct BreathingGuideView: View {
    let pattern: BreathingPattern
    let tint: Color
    let isActive: Bool

    @State private var phaseIndex = 0
    /// 0 = fully exhaled (petals folded), 1 = fully inhaled (in full bloom).
    @State private var bloom: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var label = "Ready"
    @State private var phaseRemaining: Double = 0

    private let petalCount = 6
    private let haptic = UIImpactFeedbackGenerator(style: .soft)
    private let tick = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.08))
                    .frame(width: 300, height: 300)
                    .scaleEffect(0.85 + bloom * 0.18)

                Circle()
                    .strokeBorder(tint.opacity(0.30), lineWidth: 1)
                    .frame(width: 270, height: 270)
                    .scaleEffect(0.85 + bloom * 0.15)

                flower
                    .rotationEffect(.degrees(rotation))
                    .scaleEffect(0.78 + bloom * 0.26)
                    .shadow(color: tint.opacity(0.40), radius: 36)
            }
            .frame(width: 310, height: 310)

            VStack(spacing: 4) {
                Text(label)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                Text(countdownText)
                    .font(.system(.title3, design: .rounded).weight(.medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .monospacedDigit()
                    .opacity(isActive && phaseRemaining > 0 ? 1 : 0)
            }
        }
        .onChange(of: isActive) { _, active in
            active ? begin() : rest()
        }
        .onAppear {
            withAnimation(.linear(duration: 140).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            if isActive { begin() }
        }
        .onReceive(tick) { _ in
            guard isActive else { return }
            phaseRemaining -= 0.1
            if phaseRemaining <= 0 {
                advance()
            }
        }
    }

    /// Overlapping petal circles; .screen blending brightens intersections,
    /// echoing the Apple Watch breathing flower without copying it.
    private var flower: some View {
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

    private var countdownText: String {
        "\(Int(max(phaseRemaining, 0).rounded(.up)))"
    }

    private func begin() {
        phaseIndex = pattern.phases.count - 1
        bloom = 0
        advance()
    }

    private func rest() {
        withAnimation(.easeInOut(duration: 1.4)) {
            bloom = 0
        }
        label = "Paused"
        phaseRemaining = 0
    }

    private func advance() {
        phaseIndex = (phaseIndex + 1) % pattern.phases.count
        let phase = pattern.phases[phaseIndex]
        label = phase.label
        phaseRemaining = phase.seconds
        haptic.impactOccurred()

        switch phase.kind {
        case .inhale:
            // A second stacked inhale (physiological sigh) blooms past full.
            let target: CGFloat = bloom >= 0.95 ? 1.12 : 1.0
            withAnimation(.easeInOut(duration: phase.seconds)) { bloom = target }
        case .exhale:
            withAnimation(.easeInOut(duration: phase.seconds)) { bloom = 0 }
        case .hold:
            break // hold the flower where it is
        }
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        BreathingGuideView(pattern: .box, tint: .cyan, isActive: true)
    }
}
