import SwiftUI

/// Path B coordinator: shows the wellbeing gate on first entry, then the
/// theme/intention chooser. Reuses the app's card + aurora language with a
/// deeper, night-leaning palette.
struct JourneyEntryView: View {
    @AppStorage("journeyOnboardingSeen") private var onboardingSeen = false
    @State private var showOnboarding = false

    var body: some View {
        JourneyThemesView()
            .onAppear {
                if !onboardingSeen { showOnboarding = true }
            }
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
    @State private var minutes = 15
    @State private var reflection = ""
    @State private var launch = false

    private let durations = [10, 15, 20, 25]

    var body: some View {
        ZStack {
            AuroraBackground(
                colors: [Color(red: 0.16, green: 0.20, blue: 0.46),
                         Color(red: 0.09, green: 0.10, blue: 0.26)],
                intensity: 1.0
            )
            ParticleFieldView(motion: .drift, tint: Color(red: 0.7, green: 0.74, blue: 1.0), count: 26)

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("Choose an intention")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.top, 4)

                    ForEach(JourneyTheme.all) { theme in
                        Button {
                            selectedTheme = theme
                        } label: {
                            ThemeRow(theme: theme, selected: selectedTheme?.id == theme.id)
                        }
                        .buttonStyle(.plain)
                    }

                    durationPicker
                    reflectionField
                    beginButton

                    Text("A gentle voice will guide you. You can pause, or tap “Bring me back,” at any moment — it will always return you calmly before ending.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.bottom, 28)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationTitle("Journey of Souls")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $launch) {
            if let theme = selectedTheme {
                JourneySessionView(theme: theme, minutes: minutes,
                                   adaptiveEnabled: adaptiveEnabled,
                                   reflection: reflection.isEmpty ? nil : reflection)
            }
        }
    }

    private var durationPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Length")
                .font(.headline)
                .foregroundStyle(.white)
            HStack(spacing: 8) {
                ForEach(durations, id: \.self) { m in
                    Button {
                        minutes = m
                    } label: {
                        Text("\(m)m")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                minutes == m
                                    ? AnyShapeStyle(Color(red: 0.4, green: 0.4, blue: 0.85).opacity(0.7))
                                    : AnyShapeStyle(.white.opacity(0.08)),
                                in: Capsule()
                            )
                    }
                }
            }
        }
    }

    private var reflectionField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Anything on your mind? (optional)")
                .font(.headline)
                .foregroundStyle(.white)
            TextField("", text: $reflection, axis: .vertical)
                .lineLimit(1...3)
                .textFieldStyle(.plain)
                .foregroundStyle(.white)
                .padding(12)
                .glassCard(cornerRadius: 14)
                .overlay(alignment: .topLeading) {
                    if reflection.isEmpty {
                        Text("A word or feeling to hold lightly…")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.35))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 20)
                            .allowsHitTesting(false)
                    }
                }
        }
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
                            : [Color(red: 0.32, green: 0.36, blue: 0.8), Color(red: 0.5, green: 0.36, blue: 0.82)],
                        startPoint: .leading, endPoint: .trailing
                    ),
                    in: Capsule()
                )
        }
        .disabled(selectedTheme == nil)
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
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.white)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [theme.colors[0].opacity(selected ? 0.85 : 0.5),
                                    theme.colors[1].opacity(selected ? 0.6 : 0.35)],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.white.opacity(selected ? 0.4 : 0.1), lineWidth: selected ? 1.5 : 1)
        )
    }
}

#Preview {
    NavigationStack { JourneyThemesView() }
}
