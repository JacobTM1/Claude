import SwiftUI

/// Path B coordinator: shows the wellbeing gate on first entry, then the
/// soul-journey intention chooser.
struct JourneyEntryView: View {
    @AppStorage("journeyOnboardingSeen") private var onboardingSeen = false
    @State private var showOnboarding = false

    var body: some View {
        JourneyThemesView()
            .onAppear { if !onboardingSeen { showOnboarding = true } }
            .sheet(isPresented: $showOnboarding) {
                JourneyOnboardingView(requiresAcknowledgment: true) {
                    onboardingSeen = true
                }
                .preferredColorScheme(.dark)
            }
    }
}

struct JourneyThemesView: View {
    @AppStorage("journeyAdaptiveEnabled") private var adaptiveEnabled = false
    @State private var selectedTheme: JourneyTheme?
    @State private var deep = false   // false = Gentle (~12 min), true = Deep (~25 min)
    @State private var launch = false

    private var minutes: Int { deep ? 25 : 12 }

    var body: some View {
        ZStack {
            CosmicBackground(colors: selectedTheme?.colors
                ?? [Color(red: 0.16, green: 0.12, blue: 0.34), Color(red: 0.02, green: 0.02, blue: 0.08)])

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Journey of Souls")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("Choose where to journey")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .padding(.top, 8)

                    ForEach(JourneyTheme.all) { theme in
                        Button {
                            selectedTheme = theme
                        } label: {
                            ThemeRow(theme: theme, selected: selectedTheme?.id == theme.id)
                        }
                        .buttonStyle(.plain)
                    }

                    depthPicker
                    beginButton

                    Text("A gentle voice will guide you. You can say “bring me back” at any moment — it will always return you calmly before ending.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.45))
                        .padding(.bottom, 28)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationTitle("Journey of Souls")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $launch) {
            if let theme = selectedTheme {
                if Secrets.isConfigured {
                    LiveJourneySessionView(theme: theme, minutes: minutes)
                } else {
                    JourneySessionView(theme: theme, minutes: minutes,
                                       adaptiveEnabled: adaptiveEnabled, reflection: nil)
                }
            }
        }
    }

    private var depthPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Depth")
                .font(.headline)
                .foregroundStyle(.white)
            HStack(spacing: 10) {
                depthOption(title: "Gentle", subtitle: "~12 min", isDeep: false)
                depthOption(title: "Deep", subtitle: "~25 min", isDeep: true)
            }
        }
    }

    private func depthOption(title: String, subtitle: String, isDeep: Bool) -> some View {
        Button {
            deep = isDeep
        } label: {
            VStack(spacing: 3) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(subtitle).font(.caption2).opacity(0.7)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                deep == isDeep
                    ? AnyShapeStyle(Color(red: 0.4, green: 0.34, blue: 0.78).opacity(0.7))
                    : AnyShapeStyle(.white.opacity(0.07)),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }

    private var beginButton: some View {
        Button {
            launch = selectedTheme != nil
        } label: {
            Label("Begin Journey", systemImage: "play.fill")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: selectedTheme == nil
                            ? [.gray.opacity(0.4), .gray.opacity(0.3)]
                            : [Color(red: 0.36, green: 0.30, blue: 0.78), Color(red: 0.52, green: 0.34, blue: 0.74)],
                        startPoint: .leading, endPoint: .trailing
                    ),
                    in: Capsule()
                )
        }
        .disabled(selectedTheme == nil)
        .padding(.top, 4)
    }
}

private struct ThemeRow: View {
    let theme: JourneyTheme
    let selected: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: theme.icon)
                .font(.title3)
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(.white.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(theme.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(theme.tagline)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
            }
            Spacer()
            if selected {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.white)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [theme.colors[0].opacity(selected ? 0.85 : 0.45),
                                    theme.colors[1].opacity(selected ? 0.7 : 0.35)],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.white.opacity(selected ? 0.4 : 0.12), lineWidth: selected ? 1.5 : 1)
        )
    }
}

#Preview {
    NavigationStack { JourneyThemesView() }
}
