import SwiftUI

/// The languages the app's interface and guide voice support. `backendName` is
/// what the journey backend expects so the guide speaks this language;
/// `speechLocale` is the on-device speech-recognition locale.
enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case russian = "ru"

    var id: String { rawValue }

    /// Shown in the picker, in the language's own name.
    var displayName: String {
        switch self {
        case .english: "English"
        case .russian: "Русский"
        }
    }

    var flag: String {
        switch self {
        case .english: "🇬🇧"
        case .russian: "🇷🇺"
        }
    }

    /// The language name the backend guide prompt expects.
    var backendName: String {
        switch self {
        case .english: "English"
        case .russian: "Russian"
        }
    }

    /// Locale identifier for on-device speech recognition.
    var speechLocale: String {
        switch self {
        case .english: "en-US"
        case .russian: "ru-RU"
        }
    }
}

/// Holds the currently selected interface language and persists it. Views that
/// should update live when the language changes observe this object; the app
/// root also re-creates its view tree on change so every screen refreshes.
final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published var current: AppLanguage {
        didSet { UserDefaults.standard.set(current.rawValue, forKey: Self.key) }
    }

    private static let key = "appLanguage"

    private init() {
        let stored = UserDefaults.standard.string(forKey: Self.key)
        // Default to Russian if the device's preferred language is Russian and
        // nothing has been chosen yet; otherwise English.
        if let stored, let lang = AppLanguage(rawValue: stored) {
            current = lang
        } else if Locale.preferredLanguages.first?.hasPrefix("ru") == true {
            current = .russian
        } else {
            current = .english
        }
    }
}

/// The current language, for non-view code (audio, session logic).
var appLanguage: AppLanguage { LocalizationManager.shared.current }

/// Picks the string for the current language. Keeps translations inline at the
/// call site, which is easy to read and keeps each screen self-contained.
func L(_ en: String, _ ru: String) -> String {
    appLanguage == .russian ? ru : en
}

/// Array variant, for lists of strings such as step-by-step guidance.
func L(_ en: [String], _ ru: [String]) -> [String] {
    appLanguage == .russian ? ru : en
}

/// A compact flag-based language selector used on first launch and in Settings.
struct LanguagePicker: View {
    @ObservedObject private var loc = LocalizationManager.shared

    var body: some View {
        HStack(spacing: 10) {
            ForEach(AppLanguage.allCases) { lang in
                let isOn = loc.current == lang
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) { loc.current = lang }
                } label: {
                    HStack(spacing: 8) {
                        Text(lang.flag).font(.title3)
                        Text(lang.displayName)
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.white.opacity(isOn ? 1 : 0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        isOn
                            ? AnyShapeStyle(Color(red: 0.4, green: 0.34, blue: 0.78).opacity(0.7))
                            : AnyShapeStyle(.white.opacity(0.07)),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(.white.opacity(isOn ? 0.45 : 0.12), lineWidth: isOn ? 1.5 : 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
