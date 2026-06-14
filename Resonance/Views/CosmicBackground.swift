import SwiftUI

/// A deep, slow, mysterious backdrop for the Journey of Souls path: a near-black
/// field with a faint nebula glow in the theme's colours and a sky of softly
/// twinkling stars drifting almost imperceptibly. Sacred and still, distinct
/// from the lighter aurora used elsewhere.
struct CosmicBackground: View {
    var colors: [Color] = [Color(red: 0.14, green: 0.10, blue: 0.30),
                           Color(red: 0.02, green: 0.02, blue: 0.07)]
    var starCount = 90

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                ZStack {
                    // Deep base wash.
                    RadialGradient(
                        colors: [colors.first ?? .indigo, Color(red: 0.01, green: 0.01, blue: 0.05)],
                        center: .init(x: 0.5, y: 0.42),
                        startRadius: 8,
                        endRadius: max(w, h)
                    )

                    // Two slow nebula blooms in the theme colours.
                    Circle()
                        .fill((colors.first ?? .purple).opacity(0.22))
                        .frame(width: w * 0.9)
                        .offset(x: sin(t * 0.03) * w * 0.18 - w * 0.15,
                                y: cos(t * 0.024) * h * 0.06 - h * 0.18)
                        .blur(radius: 90)
                    Circle()
                        .fill((colors.last ?? .indigo).opacity(0.5))
                        .frame(width: w * 0.8)
                        .offset(x: cos(t * 0.026 + 1.5) * w * 0.2 + w * 0.18,
                                y: sin(t * 0.02 + 0.8) * h * 0.08 + h * 0.22)
                        .blur(radius: 100)

                    // Star field — positions seeded from the index, twinkling.
                    Canvas { context, size in
                        for i in 0..<starCount {
                            let seed = Double(i)
                            let x = fract(sin(seed * 127.1) * 43758.5453) * size.width
                            let y = fract(sin(seed * 311.7) * 24634.633) * size.height
                            let base = fract(sin(seed * 74.7) * 1010.12)
                            let twinkle = 0.25 + 0.75 * (0.5 + 0.5 * sin(t * (0.4 + base) + seed))
                            let d = 1.0 + base * 2.2
                            let rect = CGRect(x: x - d / 2, y: y - d / 2, width: d, height: d)
                            context.opacity = twinkle * 0.9
                            context.fill(Ellipse().path(in: rect), with: .color(.white))
                        }
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}

private func fract(_ v: Double) -> Double { v - floor(v) }

#Preview {
    CosmicBackground()
}
