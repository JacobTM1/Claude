import SwiftUI

/// What the user is seeking. Captured at first launch and passed to the guide
/// so sessions are tailored; editable later in Settings.
enum UserGoal: String, CaseIterable, Identifiable {
    case stress = "Stress & anxiety"
    case sleep = "Better sleep"
    case focus = "Focus & clarity"
    case healing = "Emotional healing"
    case calm = "Meditation & calm"
    case soul = "Explore my soul"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .stress: "wind"
        case .sleep: "moon.stars.fill"
        case .focus: "scope"
        case .healing: "heart.circle.fill"
        case .calm: "leaf.fill"
        case .soul: "sparkles"
        }
    }

    /// Localized label shown in the picker (`rawValue` stays the stored key).
    var title: String {
        switch self {
        case .stress: L("Stress & anxiety", "Стресс и тревога")
        case .sleep: L("Better sleep", "Лучший сон")
        case .focus: L("Focus & clarity", "Фокус и ясность")
        case .healing: L("Emotional healing", "Эмоциональное исцеление")
        case .calm: L("Meditation & calm", "Медитация и покой")
        case .soul: L("Explore my soul", "Исследовать свою душу")
        }
    }

    var subtitle: String {
        switch self {
        case .stress: L("Unwind a busy, anxious mind", "Успокоить занятый, тревожный ум")
        case .sleep: L("Drift into deep, easy rest", "Погрузиться в глубокий, лёгкий отдых")
        case .focus: L("Steady, clear attention", "Ровное, ясное внимание")
        case .healing: L("Gently release what you carry", "Мягко отпустить то, что несёте")
        case .calm: L("Simple stillness and peace", "Простая тишина и покой")
        case .soul: L("Inner journeys and meaning", "Внутренние путешествия и смысл")
        }
    }
}

enum UserGoalStore {
    private static let key = "userGoals"

    /// The chosen goals as a human phrase for the guide (e.g. "Better sleep,
    /// Emotional healing"); empty if none chosen.
    static var phrase: String {
        UserDefaults.standard.string(forKey: key) ?? ""
    }

    static var selected: Set<String> {
        Set(phrase.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) })
            .filter { !$0.isEmpty }
    }

    /// The chosen goals as localized titles, for display in the current
    /// language (the stored keys stay stable English `rawValue`s).
    static var selectedTitles: String {
        UserGoal.allCases
            .filter { selected.contains($0.rawValue) }
            .map(\.title)
            .joined(separator: ", ")
    }

    static func save(_ goals: Set<String>) {
        let ordered = UserGoal.allCases.map(\.rawValue).filter { goals.contains($0) }
        UserDefaults.standard.set(ordered.joined(separator: ", "), forKey: key)
    }
}
