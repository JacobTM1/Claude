import AVFoundation

/// A soft, continuous ambient bed played under the Journey of Souls guide so
/// that pauses feel like intentional, held space rather than dead air or a
/// frozen app. It is synthesized once into a seamless loop and played on its
/// own `AVAudioPlayer` — pure output, so it never touches the microphone or
/// speech-recognition graph, and the session's echo cancellation keeps it out
/// of what the guide "hears".
final class AmbientBedPlayer {
    private var player: AVAudioPlayer?

    func start() {
        if player == nil {
            player = try? Self.makePlayer()
        }
        guard let player else { return }
        player.numberOfLoops = -1
        player.volume = 0
        player.prepareToPlay()
        player.play()
        // Fade the bed in gently so it never announces itself.
        player.setVolume(0.085, fadeDuration: 4.0)
    }

    func stop() {
        guard let player, player.isPlaying else { return }
        player.setVolume(0, fadeDuration: 2.5)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.7) { [weak player] in
            player?.stop()
        }
    }

    // MARK: - Synthesis

    private static var cachedURL: URL?

    private static func makePlayer() throws -> AVAudioPlayer {
        let url = try renderLoop()
        return try AVAudioPlayer(contentsOf: url)
    }

    private static func renderLoop() throws -> URL {
        if let cachedURL, FileManager.default.fileExists(atPath: cachedURL.path) {
            return cachedURL
        }

        let sampleRate = 44100.0
        let seconds = 8.0
        let frameCount = Int(sampleRate * seconds)

        // A low, warm pad. Every partial completes a whole number of cycles
        // over the loop length, so the end meets the start with no seam. The
        // whole pad breathes once per loop (also seamless).
        let partials: [(freq: Double, amp: Double)] = [
            (96, 0.5), (144, 0.32), (192, 0.18), (288, 0.08),
        ]
        let norm = partials.reduce(0) { $0 + $1.amp }

        var samples = [Int16](repeating: 0, count: frameCount)
        for n in 0..<frameCount {
            let t = Double(n) / sampleRate
            let breath = 0.78 + 0.22 * sin(2 * .pi * t / seconds)
            var s = 0.0
            for p in partials {
                s += p.amp * sin(2 * .pi * p.freq * t)
            }
            s = (s / norm) * breath * 0.5
            let clamped = max(-1.0, min(1.0, s))
            samples[n] = Int16(clamped * 32767)
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("resonance-bed.wav")
        try writeWav(samples: samples, sampleRate: Int(sampleRate), to: url)
        cachedURL = url
        return url
    }

    private static func writeWav(samples: [Int16], sampleRate: Int, to url: URL) throws {
        let channels = 1
        let bitsPerSample = 16
        let byteRate = sampleRate * channels * bitsPerSample / 8
        let blockAlign = channels * bitsPerSample / 8
        let dataSize = samples.count * MemoryLayout<Int16>.size

        var data = Data()
        func appendString(_ s: String) { data.append(s.data(using: .ascii)!) }
        func append32(_ v: UInt32) { var x = v.littleEndian; data.append(Data(bytes: &x, count: 4)) }
        func append16(_ v: UInt16) { var x = v.littleEndian; data.append(Data(bytes: &x, count: 2)) }

        appendString("RIFF"); append32(UInt32(36 + dataSize)); appendString("WAVE")
        appendString("fmt "); append32(16); append16(1); append16(UInt16(channels))
        append32(UInt32(sampleRate)); append32(UInt32(byteRate))
        append16(UInt16(blockAlign)); append16(UInt16(bitsPerSample))
        appendString("data"); append32(UInt32(dataSize))
        samples.withUnsafeBytes { raw in data.append(contentsOf: raw) }

        try data.write(to: url)
    }
}
