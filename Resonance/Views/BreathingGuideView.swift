import SwiftUI
import UIKit

/// The animated breathing circle. Expands on inhale, contracts on exhale,
/// holds in place on holds, with a soft haptic tap at each phase change.
struct BreathingGuideView: View {
    let pattern: BreathingPattern
    let tint: Color
    let isActive: Bool

    @State private var phaseIndex = 0
    @State private var scale: CGFloat = BreathingGuideView.exhaledScale
    @State private var label = "Ready"
    @State private var phaseRemaining: Double = 0

    private static let exhaledScale: CGFloat = 0.58
    private static let inhaledScale: CGFloat = 1.0
    private let haptic = UIImpactFeedbackGenerator(style: .soft)
    private let tick = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Circle()
                .fill(tint.opacity(0.10))
                .frame(width: 300, height: 300)
                .scaleEffect(scale * 1.12)

            Circle()
                .strokeBorder(tint.opacity(0.35), lineWidth: 1)
                .frame(width: 264, height: 264)
                .scaleEffect(scale * 1.06)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [tint.opacity(0.85), tint.opacity(0.35)],
                        center: .center,
                        startRadius: 10,
                        endRadius: 130
                    )
                )
                .frame(width: 230, height: 230)
                .scaleEffect(scale)
                .shadow(color: tint.opacity(0.45), radius: 40)

            VStack(spacing: 6) {
                Text(label)
                    .font(.title2.weight(.semibold))
                    .contentTransition(.opacity)
                if isActive, phaseRemaining > 0 {
                    Text("\(Int(phaseRemaining.rounded(.up)))")
                        .font(.system(.title, design: .rounded).weight(.medium))
                        .opacity(0.85)
                        .monospacedDigit()
                }
            }
            .foregroundStyle(.white)
        }
        .frame(height: 340)
        .onChange(of: isActive) { _, active in
            active ? begin() : rest()
        }
        .onAppear {
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

    private func begin() {
        phaseIndex = pattern.phases.count - 1
        scale = Self.exhaledScale
        advance()
    }

    private func rest() {
        withAnimation(.easeInOut(duration: 1.2)) {
            scale = Self.exhaledScale
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
            // A second stacked inhale (physiological sigh) swells past full.
            let target: CGFloat = scale >= Self.inhaledScale - 0.05 ? 1.08 : Self.inhaledScale
            withAnimation(.easeInOut(duration: phase.seconds)) { scale = target }
        case .exhale:
            withAnimation(.easeInOut(duration: phase.seconds)) { scale = Self.exhaledScale }
        case .hold:
            break // keep current size
        }
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        BreathingGuideView(pattern: .box, tint: .cyan, isActive: true)
    }
}
