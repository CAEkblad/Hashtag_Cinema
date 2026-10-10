import AVFoundation
import UIKit

/// Reads a script with the best voice on the phone and mixes it into a reel.
/// Everything runs on the device.
final class VoiceoverWriter: NSObject, AVSpeechSynthesizerDelegate, @unchecked Sendable {
    enum VoiceError: Error { case noAudio }

    private let synth = AVSpeechSynthesizer()
    private var file: AVAudioFile?
    private var continuation: CheckedContinuation<Void, Error>?
    private let lock = NSLock()
    private var wroteFrames = false

    override init() {
        super.init()
        synth.delegate = self
    }

    /// The most natural sounding US English voice installed.
    static func bestVoice() -> AVSpeechSynthesisVoice? {
        let english = AVSpeechSynthesisVoice.speechVoices().filter { $0.language == "en-US" }
        return english.first { $0.quality == .premium }
            ?? english.first { $0.quality == .enhanced }
            ?? AVSpeechSynthesisVoice(language: "en-US")
    }

    /// About how long the script takes to read, at the rate we use.
    static func estimatedSeconds(_ text: String) -> Double {
        let words = text.split { $0.isWhitespace || $0.isNewline }.count
        return Double(words) / 2.6
    }

    func write(_ text: String, to url: URL) async throws {
        try? FileManager.default.removeItem(at: url)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = Self.bestVoice()
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.postUtteranceDelay = 0.2

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            lock.lock()
            self.continuation = continuation
            lock.unlock()
            synth.write(utterance) { [weak self] buffer in
                guard let self else { return }
                guard let pcm = buffer as? AVAudioPCMBuffer else { return }
                if pcm.frameLength == 0 {
                    self.finish(nil)
                    return
                }
                do {
                    if self.file == nil {
                        self.file = try AVAudioFile(forWriting: url, settings: pcm.format.settings, commonFormat: pcm.format.commonFormat, interleaved: pcm.format.isInterleaved)
                    }
                    try self.file?.write(from: pcm)
                    self.wroteFrames = true
                } catch {
                    self.finish(error)
                }
            }
        }
        file = nil
        if !wroteFrames { throw VoiceError.noAudio }
    }

    private func finish(_ error: Error?) {
        lock.lock()
        let pending = continuation
        continuation = nil
        lock.unlock()
        guard let pending else { return }
        if let error { pending.resume(throwing: error) } else { pending.resume() }
    }

    // Some iOS versions skip the final empty buffer, so the delegate finishes too.
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        finish(nil)
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        finish(nil)
    }
}

enum ReelMixer {
    enum MixError: Error { case noVideo, export }

    /// Lays the voiceover over the video, starting half a second in and trimmed to fit.
    static func addVoiceover(video: URL, audio: URL) async throws -> URL {
        let output = FileManager.default.temporaryDirectory.appendingPathComponent("closeup-reel-vo-\(UUID().uuidString.prefix(6)).mp4")
        try? FileManager.default.removeItem(at: output)

        let videoAsset = AVURLAsset(url: video)
        let audioAsset = AVURLAsset(url: audio)
        guard let videoTrack = try await videoAsset.loadTracks(withMediaType: .video).first else { throw MixError.noVideo }
        let videoDuration = try await videoAsset.load(.duration)

        let composition = AVMutableComposition()
        let compVideo = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        try compVideo?.insertTimeRange(CMTimeRange(start: .zero, duration: videoDuration), of: videoTrack, at: .zero)

        if let audioTrack = try await audioAsset.loadTracks(withMediaType: .audio).first {
            let audioDuration = try await audioAsset.load(.duration)
            let start = CMTime(seconds: 0.5, preferredTimescale: 600)
            let room = CMTimeSubtract(videoDuration, start)
            let length = CMTimeMinimum(audioDuration, room)
            if length.seconds > 0 {
                let compAudio = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
                try compAudio?.insertTimeRange(CMTimeRange(start: .zero, duration: length), of: audioTrack, at: start)
            }
        }

        guard let export = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else { throw MixError.export }
        if #available(iOS 18, *) {
            try await export.export(to: output, as: .mp4)
        } else {
            export.outputURL = output
            export.outputFileType = .mp4
            await export.export()
            guard export.status == .completed else { throw export.error ?? MixError.export }
        }
        return output
    }

    /// A ready to read script for a listing, about as long as the reel.
    static func listingScript(_ listing: Listing, agentName: String, seconds: Double) -> String {
        let first = agentName.split(separator: " ").first.map(String.init) ?? agentName
        let street = listing.address.split(separator: ",").first.map(String.init) ?? listing.address
        var parts: [String] = []
        switch listing.status {
        case .comingSoon: parts.append("Coming soon to \(listing.city?.name ?? "the market"): \(street).")
        case .sold: parts.append("Just sold: \(street).")
        case .underContract: parts.append("Under contract: \(street).")
        case .active: parts.append("Welcome to \(street).")
        }
        parts.append("\(listing.beds) bedrooms and \(listing.bathsLabel) baths\(listing.squareFeet.map { ", with \($0.formatted()) square feet" } ?? "").")
        let phrases = listing.features.prefix(seconds > 20 ? 4 : 2).map(\.phrase)
        if !phrases.isEmpty {
            parts.append("You'll love \(phrases.count == 1 ? phrases[0] : phrases.dropLast().joined(separator: ", ") + " and " + (phrases.last ?? "")).")
        }
        if listing.status == .active || listing.status == .comingSoon {
            parts.append("Offered at \(listing.priceLabel).")
        }
        parts.append("Message \(first) to see it.")
        return parts.joined(separator: " ")
    }
}
