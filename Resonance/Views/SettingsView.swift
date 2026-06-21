import SwiftUI

/// App settings, focused on Journey of Souls: replay the onboarding gate,
/// toggle adaptive (LLM) content, and tune the guiding voice + pacing.
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var loc = LocalizationManager.shared
    @AppStorage("journeyAdaptiveEnabled") private var adaptiveEnabled = false
    @AppStorage("voiceRate") private var voiceRate = 0.5
    @AppStorage("voicePitch") private var voicePitch = 0.45
    @AppStorage("voiceVolume") private var voiceVolume = 0.95
    @State private var showOnboarding = false
    @State private var showGoals = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        section(L("Language", "Язык")) {
                            LanguagePicker()
                        }

                        section(L("You", "Вы")) {
                            Button {
                                showGoals = true
                            } label: {
                                row(icon: "target", title: L("Your goals", "Ваши цели"),
                                    trailing: L("Edit", "Изменить"))
                            }
                            if !UserGoalStore.phrase.isEmpty {
                                Text(UserGoalStore.selectedTitles)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.55))
                            }
                        }

                        section(L("Journey of Souls", "Путешествие душ")) {
                            Button {
                                showOnboarding = true
                            } label: {
                                row(icon: "book",
                                    title: L("Replay intro & wellbeing guide", "Повторить вступление и памятку"),
                                    trailing: L("View", "Открыть"))
                            }

                            Toggle(isOn: $adaptiveEnabled) {
                                VStack(alignment: .leading, spacing: 3) {
                                    Label(L("Adaptive guidance", "Адаптивное ведение"), systemImage: "wand.and.stars")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.white)
                                    Text(L("Vary scripts with AI when available. Off uses the built-in guided scripts (works offline).",
                                           "Менять сценарии с помощью ИИ, когда доступно. Выкл — встроенные сценарии (работают офлайн)."))
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.55))
                                }
                            }
                            .tint(Color(red: 0.5, green: 0.4, blue: 0.85))
                            .padding(.vertical, 4)
                        }

                        section(L("Guiding voice", "Голос гида")) {
                            slider(L("Speed", "Скорость"), value: $voiceRate,
                                   low: L("Slow", "Медленно"), high: L("Faster", "Быстрее"))
                            slider(L("Pitch", "Тон"), value: $voicePitch,
                                   low: L("Low", "Низкий"), high: L("High", "Высокий"))
                            slider(L("Volume", "Громкость"), value: $voiceVolume,
                                   low: L("Soft", "Тихо"), high: L("Loud", "Громко"))
                            Text(L("Changes apply to your next journey.", "Изменения применятся к следующему путешествию."))
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(L("Settings", "Настройки"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L("Done", "Готово")) { dismiss() }
                        .foregroundStyle(.white)
                }
            }
            .sheet(isPresented: $showOnboarding) {
                JourneyOnboardingView(requiresAcknowledgment: false)
                    .preferredColorScheme(.dark)
            }
            .sheet(isPresented: $showGoals) {
                GoalOnboardingView(isEditing: true).preferredColorScheme(.dark)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .tracking(1.5)
                .foregroundStyle(.white.opacity(0.45))
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
    }

    private func row(icon: String, title: String, trailing: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
            Spacer()
            Text(trailing)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    private func slider(_ label: String, value: Binding<Double>, low: String, high: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white)
            HStack(spacing: 10) {
                Text(low).font(.caption2).foregroundStyle(.white.opacity(0.45))
                Slider(value: value, in: 0...1)
                    .tint(Color(red: 0.5, green: 0.4, blue: 0.85))
                Text(high).font(.caption2).foregroundStyle(.white.opacity(0.45))
            }
        }
    }
}

#Preview {
    SettingsView()
}
