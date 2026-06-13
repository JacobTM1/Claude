import AVFoundation

/// Plays the guide's synthesized voice (MP3 data from the backend) and
/// resolves when the line finishes — so the session can hold the pause that
/// follows. `stop()` ends playback early and still resolves the waiter.
final class VoicePlayer: NSObject, AVAudioPlayerDelegate {
    private var player: AVAudioPlayer?
    private var continuation: CheckedContinuation<Void, Never>?

    /// Plays the audio and returns when it ends (or is stopped / fails).
    func play(_ data: Data) async {
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            continuation = cont
            do {
                let p = try AVAudioPlayer(data: data)
                p.delegate = self
                player = p
                p.prepareToPlay()
                p.play()
            } catch {
                resolve()
            }
        }
    }

    func stop() {
        player?.stop()
        player = nil
        resolve()
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        resolve()
    }

    private func resolve() {
        guard let cont = continuation else { return }
        continuation = nil
        cont.resume()
    }
}
