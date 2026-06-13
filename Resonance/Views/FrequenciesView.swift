import SwiftUI

/// Path A — the original experience: the gallery of frequency + guided-breath
/// modes. Lifted verbatim out of the old home screen so nothing about this
/// path changes; only its entry point moved up a level.
struct FrequenciesView: View {
    @State private var showScience = false

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
    ]

    var body: some View {
        ZStack {
            AuroraBackground(colors: [.indigo, .purple], intensity: 1.15)
            ParticleFieldView(
                motion: .drift,
                tint: Color(red: 0.72, green: 0.76, blue: 1.0),
                count: 22
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headphonesTip
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(MeditationMode.all) { mode in
                            NavigationLink(value: ModeRoute(id: mode.id)) {
                                ModeCard(mode: mode)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Frequencies")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showScience = true
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .sheet(isPresented: $showScience) {
            ScienceView()
        }
    }

    private var headphonesTip: some View {
        HStack(spacing: 12) {
            Image(systemName: "airpods.max")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.85))
            Text("Wear headphones — binaural beats need a different tone in each ear.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: 16)
    }
}

/// Navigation token for a frequency session (kept distinct from plain
/// strings so it never collides with other String routes on the stack).
struct ModeRoute: Hashable {
    let id: String
}

struct ModeCard: View {
    let mode: MeditationMode

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: mode.icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(.white.opacity(0.14), in: Circle())

            Spacer(minLength: 14)

            Text(mode.name)
                .font(.headline)
                .foregroundStyle(.white)
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.leading)

            Text(mode.bandLabel)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.85))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.white.opacity(0.14), in: Capsule())
                .padding(.top, 6)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 172)
        .background(
            LinearGradient(
                colors: [mode.colors[0].opacity(0.75), mode.colors[1].opacity(0.45)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(.white.opacity(0.10))
        )
    }
}
