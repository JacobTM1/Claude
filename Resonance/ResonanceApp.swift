import SwiftUI

@main
struct ResonanceApp: App {
    @StateObject private var loc = LocalizationManager.shared

    var body: some Scene {
        WindowGroup {
            HomeView()
                .preferredColorScheme(.dark)
                .environmentObject(loc)
        }
    }
}
