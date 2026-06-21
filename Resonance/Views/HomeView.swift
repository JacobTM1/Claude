import SwiftUI

/// Top-level routes reachable from the home chooser.
enum HomeRoute: Hashable {
    case frequencies
    case journey
}

/// The home screen now presents the app's two experiences as a top-level
/// choice, in the existing visual language: Path A (Frequencies & Guided
/// Meditation) and Path B (Journey of Souls).
struct HomeView: View {
    @State private var showSettings = false
    @AppStorage("goalOnboardingSeen") private var goalOnboardingSeen = false
    @State private var showGoalOnboarding = false

    var body: some View {
        NavigationStack {
            ZStack {
                AuroraBackground(colors: [.indigo, .purple], intensity: 1.15)
                ParticleFieldView(
                    motion: .drift,
                    tint: Color(red: 0.72, green: 0.76, blue: 1.0),
                    count: 22
                )

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        header

                        NavigationLink(value: HomeRoute.frequencies) {
                            PathCard(
                                title: "Frequencies & Guided Meditation",
                                subtitle: "Stress relief, focus, healing, deep meditation — binaural tones with guided breath.",
                                icon: "waveform.path",
                                colors: [Color(red: 0.30, green: 0.30, blue: 0.78),
                                         Color(red: 0.42, green: 0.30, blue: 0.74)]
                            )
                        }
                        .buttonStyle(.plain)

                        NavigationLink(value: HomeRoute.journey) {
                            PathCard(
                                title: "Journey of Souls",
                                subtitle: "A calm, guided inner journey — imagery and reflection, in your own quiet space.",
                                icon: "moon.stars.fill",
                                colors: [Color(red: 0.16, green: 0.20, blue: 0.46),
                                         Color(red: 0.10, green: 0.10, blue: 0.28)],
                                deepMood: true
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
            .navigationDestination(for: HomeRoute.self) { route in
                switch route {
                case .frequencies: FrequenciesView()
                case .journey: JourneyEntryView()
                }
            }
            .navigationDestination(for: ModeRoute.self) { route in
                if let mode = MeditationMode.all.first(where: { $0.id == route.id }) {
                    SessionView(mode: mode)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .fullScreenCover(isPresented: $showGoalOnboarding) {
                GoalOnboardingView().preferredColorScheme(.dark)
            }
            .onAppear {
                if !goalOnboardingSeen { showGoalOnboarding = true }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Resonance")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("Choose your path")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.55))
        }
        .padding(.top, 8)
    }
}

private struct PathCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let colors: [Color]
    var deepMood = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(.white.opacity(0.14), in: Circle())

            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                Text("Enter")
                Image(systemName: "arrow.right")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white.opacity(0.9))
            .padding(.top, 2)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 230)
        .background(
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
        .overlay(alignment: .topTrailing) {
            if deepMood {
                // A few faint stars to mark the cosmos-leaning path.
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.35))
                    .padding(20)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .strokeBorder(.white.opacity(0.10))
        )
    }
}

#Preview {
    HomeView()
}
