import Foundation
import AVFoundation

class PlaybackViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlayingBackingTrack = false
    @Published var isBackingTrackPaused = false
    @Published var isPlayingRecording = false
    @Published var duration: TimeInterval = 0
    @Published var currentTime: TimeInterval = 0
    @Published var backingTrackName: String?
    @Published var lastError: String?

    var backingTrackPlayer: AVAudioPlayer?
    var recordingPlayer: AVAudioPlayer?

    private var timer: Timer?

    func importBackingTrack(from sourceURL: URL) throws {
        let fileManager = FileManager.default
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let backingTracksDir = documents.appendingPathComponent("backing-tracks", isDirectory: true)

        try fileManager.createDirectory(at: backingTracksDir, withIntermediateDirectories: true)

        let ext = sourceURL.pathExtension.isEmpty ? "m4a" : sourceURL.pathExtension
        let destination = backingTracksDir
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(ext)

        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.copyItem(at: sourceURL, to: destination)

        loadBackingTrack(url: destination, displayName: sourceURL.lastPathComponent)
    }

    func loadBackingTrack(url: URL, displayName: String? = nil) {
        do {
            backingTrackPlayer = try AVAudioPlayer(contentsOf: url)
            backingTrackPlayer?.delegate = self
            backingTrackPlayer?.prepareToPlay()
            duration = backingTrackPlayer?.duration ?? 0
            backingTrackName = displayName ?? url.lastPathComponent
            isBackingTrackPaused = false
            lastError = nil
        } catch {
            lastError = "Error loading backing track: \(error.localizedDescription)"
        }
    }

    func toggleBackingTrack() {
        guard let player = backingTrackPlayer else { return }

        if player.isPlaying {
            pauseBackingTrack()
        } else {
            player.play()
            isPlayingBackingTrack = true
            isBackingTrackPaused = false
            startTimer()
        }
    }

    func pauseBackingTrack() {
        backingTrackPlayer?.pause()
        isPlayingBackingTrack = false
        isBackingTrackPaused = true
        stopTimer()
    }

    func resumeBackingTrack() {
        guard let player = backingTrackPlayer, isBackingTrackPaused else { return }
        player.play()
        isPlayingBackingTrack = true
        isBackingTrackPaused = false
        startTimer()
    }

    func stopBackingTrack() {
        backingTrackPlayer?.stop()
        backingTrackPlayer?.currentTime = 0
        isPlayingBackingTrack = false
        isBackingTrackPaused = false
        stopTimer()
        currentTime = 0
    }

    func playRecording(url: URL) {
        stopBackingTrack()

        do {
            recordingPlayer = try AVAudioPlayer(contentsOf: url)
            recordingPlayer?.delegate = self
            recordingPlayer?.play()
            isPlayingRecording = true
        } catch {
            lastError = "Error playing recording: \(error.localizedDescription)"
        }
    }

    func stopRecordingPlayback() {
        recordingPlayer?.stop()
        isPlayingRecording = false
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if let player = self.backingTrackPlayer {
                self.currentTime = player.currentTime
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if player == recordingPlayer {
            isPlayingRecording = false
        } else if player == backingTrackPlayer {
            isPlayingBackingTrack = false
            isBackingTrackPaused = false
            stopTimer()
            currentTime = 0
        }
    }
}
