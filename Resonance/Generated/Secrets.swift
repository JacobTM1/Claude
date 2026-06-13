// Build-time configuration. The real values are injected by CI from GitHub
// Actions secrets (BACKEND_URL, APP_SHARED_SECRET) — see the workflow's
// "Inject backend secrets" step. This committed copy holds empty placeholders
// so the repo never contains the secret and local builds still compile.
//
// When empty, the app falls back to the fully on-device (scripted) Journey.
enum Secrets {
    static let backendURL = ""
    static let appSharedSecret = ""
    static var isConfigured: Bool { !backendURL.isEmpty && !appSharedSecret.isEmpty }
}
