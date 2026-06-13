import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            // matches the web app's deep-space background so there is no flash
            // of white before the map's WebGL canvas paints.
            Color(red: 0.02, green: 0.027, blue: 0.05)
                .ignoresSafeArea()
            WeatherWebView()
                .ignoresSafeArea()
        }
    }
}

#Preview {
    ContentView()
}
