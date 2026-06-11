import SwiftUI

struct HomeView: View {
    @State private var showScience = false

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        header
                        headphonesTip
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(MeditationMode.all) { mode in
                                NavigationLink(value: mode.id) {
                                    ModeCard(mode: mode)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
            }
            .navigationDestination(for: String.self) { id in
                if let mode = MeditationMode.all.first(where: { $0.id == id }) {
                    SessionView(mode: mode)
                }
            }
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
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Resonance")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("Frequency sound & guided breath")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.55))
        }
        .padding(.top, 8)
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

private struct ModeCard: View {
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

#Preview {
    HomeView()
}
