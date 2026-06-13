import SwiftUI

@main
struct LiveEarthApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .ignoresSafeArea()
                .statusBarHidden(false)
        }
    }
}
