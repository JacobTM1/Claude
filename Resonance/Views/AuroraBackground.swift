import SwiftUI

/// A slowly drifting aurora of soft color blobs over the midnight base.
/// The motion is deliberately glacial — calm comes from movement that is
/// felt rather than watched.
struct AuroraBackground: View {
    let colors: [Color]
    var intensity: Double = 1.0

    private var primary: Color { colors.first ?? .indigo }
    private var secondary: Color { colors.last ?? .purple }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                ZStack {
                    Color(red: 0.03, green: 0.04, blue: 0.10)

                    Circle()
                        .fill(primary.opacity(0.32 * intensity))
                        .frame(width: w * 1.1)
                        .offset(
                            x: sin(t * 0.060) * w * 0.28,
                            y: cos(t * 0.045) * h * 0.10 - h * 0.28
                        )
                        .blur(radius: 70)

                    Circle()
                        .fill(secondary.opacity(0.26 * intensity))
                        .frame(width: w * 0.95)
                        .offset(
                            x: cos(t * 0.050 + 2.1) * w * 0.30,
                            y: sin(t * 0.038 + 1.3) * h * 0.12 + h * 0.30
                        )
                        .blur(radius: 80)

                    Circle()
                        .fill(primary.opacity(0.18 * intensity))
                        .frame(width: w * 0.7)
                        .offset(
                            x: sin(t * 0.035 + 4.2) * w * 0.35,
                            y: cos(t * 0.052 + 3.0) * h * 0.18
                        )
                        .blur(radius: 90)
                }
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    AuroraBackground(colors: [.indigo, .purple])
}
