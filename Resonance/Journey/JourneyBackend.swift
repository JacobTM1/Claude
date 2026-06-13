import Foundation

/// One conversational turn message exchanged with the backend.
struct ChatMsg: Codable {
    let role: String   // "assistant" or "user"
    let text: String
}

/// One spoken line returned by the guide, with the silence to hold after it.
struct GuideLine: Codable {
    let text: String
    let pauseMsAfter: Int
}

/// The guide's response for a single turn.
struct TurnResponse: Codable {
    let speech: [GuideLine]
    let phase: String
    let awaitingResponse: Bool
    let sessionComplete: Bool
}

private struct TurnRequest: Codable {
    let theme: String
    let minutes: Int
    let history: [ChatMsg]
    let userSpeech: String?
}

private struct TTSRequest: Codable {
    let text: String
}

enum JourneyClientError: Error {
    case notConfigured
    case badURL
    case http(Int)
}

/// Talks to the Resonance backend: the conversational guide (`/journey/turn`)
/// and the voice synthesizer (`/tts`). The base URL and shared secret are
/// injected at build time via `Secrets`.
struct JourneyClient {
    private let baseURL = Secrets.backendURL
    private let secret = Secrets.appSharedSecret

    private func request(path: String) throws -> URLRequest {
        guard Secrets.isConfigured else { throw JourneyClientError.notConfigured }
        guard let url = URL(string: baseURL + path) else { throw JourneyClientError.badURL }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(secret, forHTTPHeaderField: "x-app-secret")
        req.timeoutInterval = 60
        return req
    }

    /// Asks the guide for the next turn given everything said so far.
    func turn(theme: String, minutes: Int, history: [ChatMsg], userSpeech: String?) async throws -> TurnResponse {
        var req = try request(path: "/journey/turn")
        req.httpBody = try JSONEncoder().encode(
            TurnRequest(theme: theme, minutes: minutes, history: history, userSpeech: userSpeech)
        )
        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            throw JourneyClientError.http(http.statusCode)
        }
        return try JSONDecoder().decode(TurnResponse.self, from: data)
    }

    /// Synthesizes one line into spoken audio (MP3 bytes) via the backend.
    func tts(text: String) async throws -> Data {
        var req = try request(path: "/tts")
        req.httpBody = try JSONEncoder().encode(TTSRequest(text: text))
        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            throw JourneyClientError.http(http.statusCode)
        }
        return data
    }
}
