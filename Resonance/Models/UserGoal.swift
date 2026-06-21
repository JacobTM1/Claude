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

    var subtitle: String {
        switch self {
        case .stress: "Unwind a busy, anxious mind"
        case .sleep: "Drift into deep, easy rest"
        case .focus: "Steady, clear attention"
        case .healing: "Gently release what you carry"
        case .calm: "Simple stillness and peace"
        case .soul: "Inner journeys and meaning"
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

    static func save(_ goals: Set<String>) {
        let ordered = UserGoal.allCases.map(\.rawValue).filter { goals.contains($0) }
        UserDefaults.standard.set(ordered.joined(separator: ", "), forKey: key)
    }
}
