import SwiftUI

/// How a mode's energy particles move during a session. Each mode gets its
/// own motion so the visualization matches the practice: energy rising up
/// the spine for deep meditation, stars sinking for sleep, thoughts held
/// in orbit for focus, a loose drift for calm.
enum ParticleMotion {
    case rise
    case fall
    case orbit
    case drift
}

/// A lightweight, stateless particle layer drawn with Canvas. Positions are
/// pure functions of time and a per-particle seed, so there is nothing to
/// update or store — and pausing the session simply leaves it floating.
struct ParticleFieldView: View {
    let motion: ParticleMotion
    let tint: Color
    var count: Int = 28

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                for i in 0..<count {
                    let seed = Double(i) * 127.1
                    let r1 = fract(sin(seed) * 43758.5453)
                    let r2 = fract(sin(seed * 1.7) * 12543.879)
                    let particle = position(
                        time: t, r1: r1, r2: r2, seed: seed, in: size
                    )
                    let diameter = 2.0 + r2 * 4.0
                    let rect = CGRect(
                        x: particle.x - diameter / 2,
                        y: particle.y - diameter / 2,
                        width: diameter,
                        height: diameter
                    )
                    context.opacity = particle.opacity
                    context.fill(Ellipse().path(in: rect), with: .color(tint))
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func position(
        time t: Double, r1: Double, r2: Double, seed: Double, in size: CGSize
    ) -> (x: Double, y: Double, opacity: Double) {
        switch motion {
        case .rise:
            let progress = fract(t * (0.030 + r1 * 0.035) + r2)
            let x = r1 * size.width + sin(t * 0.5 + seed) * 14
            let y = size.height * (1.0 - progress)
            return (x, y, sin(progress * .pi) * 0.65)

        case .fall:
            let progress = fract(t * (0.020 + r1 * 0.025) + r2)
            let x = r1 * size.width + sin(t * 0.3 + seed) * 10
            let y = size.height * progress
            return (x, y, sin(progress * .pi) * 0.55)

        case .orbit:
            let angle = t * (0.10 + r1 * 0.12) + seed
            let radius = size.width * (0.22 + r2 * 0.26)
            let x = size.width / 2 + cos(angle) * radius
            let y = size.height / 2 + sin(angle) * radius * 0.5
            return (x, y, 0.30 + 0.30 * (0.5 + 0.5 * sin(t * 0.8 + seed)))

        case .drift:
            let x = r1 * size.width + sin(t * 0.12 + seed) * 32
            let y = r2 * size.height + cos(t * 0.10 + seed * 2.3) * 26
            return (x, y, 0.20 + 0.30 * (0.5 + 0.5 * sin(t * 0.35 + seed)))
        }
    }
}

private func fract(_ value: Double) -> Double {
    value - floor(value)
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        ParticleFieldView(motion: .rise, tint: .indigo)
    }
}
