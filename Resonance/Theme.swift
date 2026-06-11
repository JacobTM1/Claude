import SwiftUI

enum Theme {
    /// Deep midnight backdrop used across the app.
    static let background = LinearGradient(
        colors: [
            Color(red: 0.03, green: 0.04, blue: 0.10),
            Color(red: 0.07, green: 0.09, blue: 0.20),
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    static func sessionBackground(for mode: MeditationMode) -> LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.03, green: 0.04, blue: 0.10),
                mode.colors[0].opacity(0.35),
                Color(red: 0.03, green: 0.04, blue: 0.10),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

extension View {
    /// Frosted card treatment used for tips, chips and control trays.
    func glassCard(cornerRadius: CGFloat = 20) -> some View {
        background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.08))
            )
    }
}

func formatTime(_ seconds: Int) -> String {
    String(format: "%d:%02d", seconds / 60, seconds % 60)
}
