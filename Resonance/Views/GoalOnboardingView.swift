import SwiftUI

/// First-launch (and editable) goal picker: "What brings you here?" The choices
/// are stored and passed to the guide so sessions are tailored.
struct GoalOnboardingView: View {
    /// First-run shows "Continue"; editing from Settings shows "Save".
    var isEditing = false
    var onComplete: () -> Void = {}

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var loc = LocalizationManager.shared
    @AppStorage("goalOnboardingSeen") private var seen = false
    @State private var selected: Set<String> = UserGoalStore.selected

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ZStack {
            CosmicBackground(colors: [Color(red: 0.16, green: 0.13, blue: 0.34),
                                      Color(red: 0.02, green: 0.02, blue: 0.08)])

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(isEditing ? L("Your goals", "Ваши цели")
                                       : L("What brings you here?", "Что привело вас сюда?"))
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text(L("Pick what matters to you. Your guide will tailor each session to it. You can change this anytime.",
                               "Выберите то, что важно для вас. Гид подстроит каждую сессию под это. Вы можете изменить выбор в любой момент."))
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.65))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 16)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(L("Language", "Язык").uppercased())
                            .font(.caption.weight(.semibold))
                            .tracking(1.5)
                            .foregroundStyle(.white.opacity(0.45))
                        LanguagePicker()
                    }

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(UserGoal.allCases) { goal in
                            goalCard(goal)
                        }
                    }

                    Button(action: complete) {
                        Text(isEditing ? L("Save", "Сохранить") : L("Continue", "Продолжить"))
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: selected.isEmpty
                                        ? [.gray.opacity(0.4), .gray.opacity(0.3)]
                                        : [Color(red: 0.36, green: 0.30, blue: 0.78),
                                           Color(red: 0.52, green: 0.34, blue: 0.74)],
                                    startPoint: .leading, endPoint: .trailing
                                ),
                                in: Capsule()
                            )
                    }
                    .disabled(selected.isEmpty)
                    .padding(.top, 4)
                    .padding(.bottom, 28)
                }
                .padding(.horizontal, 20)
            }
        }
        .interactiveDismissDisabled(!isEditing)
    }

    private func goalCard(_ goal: UserGoal) -> some View {
        let isOn = selected.contains(goal.rawValue)
        return Button {
            if isOn { selected.remove(goal.rawValue) } else { selected.insert(goal.rawValue) }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: goal.icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(.white.opacity(0.14), in: Circle())
                Text(goal.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                Text(goal.subtitle)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
            .background(
                .white.opacity(isOn ? 0.16 : 0.06),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(.white.opacity(isOn ? 0.5 : 0.1), lineWidth: isOn ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func complete() {
        UserGoalStore.save(selected)
        seen = true
        onComplete()
        dismiss()
    }
}

#Preview {
    GoalOnboardingView()
}
