import Foundation
import AVFoundation

class PlaybackViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlayingBackingTrack = false
    @Published var isBackingTrackPaused = false
    @Published var isPlayingRecording = false
    @Published var currentlyPlayingRecordingURL: URL?
    @Published var duration: TimeInterval = 0
    @Published var currentTime: TimeInterval = 0
    @Published var backingTrackName: String?
    @Published var lastError: String?

    var backingTrackPlayer: AVAudioPlayer?
    var recordingPlayer: AVAudioPlayer?

    private var backingTrackURL: URL?

    private var timer: Timer?

    private let defaults: UserDefaults
    private static let storedFileNameKey = "backingTrack.fileName"
    private static let storedDisplayNameKey = "backingTrack.displayName"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        super.init()
        restoreBackingTrack()
    }

    private var backingTracksDirectory: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("backing-tracks", isDirectory: true)
    }

    func importBackingTrack(from sourceURL: URL) throws {
        let fileManager = FileManager.default
        let backingTracksDir = backingTracksDirectory

        try fileManager.createDirectory(at: backingTracksDir, withIntermediateDirectories: true)

        let ext = sourceURL.pathExtension.isEmpty ? "m4a" : sourceURL.pathExtension
        let destination = backingTracksDir
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(ext)

        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.copyItem(at: sourceURL, to: destination)

        let previousURL = backingTrackURL
        loadBackingTrack(url: destination, displayName: sourceURL.lastPathComponent)

        // Persist by file name (not absolute path — the sandbox container path
        // can change between launches) so the track can be restored on relaunch.
        defaults.set(destination.lastPathComponent, forKey: Self.storedFileNameKey)
        defaults.set(sourceURL.lastPathComponent, forKey: Self.storedDisplayNameKey)

        if let previousURL, previousURL != destination {
            try? fileManager.removeItem(at: previousURL)
        }
    }

    /// Reloads the most recently imported backing track from the sandbox, if it
    /// still exists, so the user's track survives an app relaunch.
    func restoreBackingTrack() {
        guard let fileName = defaults.string(forKey: Self.storedFileNameKey) else { return }
        let url = backingTracksDirectory.appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: url.path) else {
            // The file is gone; clear the stale pointer.
            defaults.removeObject(forKey: Self.storedFileNameKey)
            defaults.removeObject(forKey: Self.storedDisplayNameKey)
            return
        }
        let displayName = defaults.string(forKey: Self.storedDisplayNameKey)
        loadBackingTrack(url: url, displayName: displayName)
    }

    private func loadBackingTrack(url: URL, displayName: String? = nil) {
        do {
            backingTrackPlayer = try AVAudioPlayer(contentsOf: url)
            backingTrackPlayer?.delegate = self
            backingTrackPlayer?.prepareToPlay()
            duration = backingTrackPlayer?.duration ?? 0
            backingTrackName = displayName ?? url.lastPathComponent
            backingTrackURL = url
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

    /// Starts the given recording, or stops it if it is already the one playing.
    func togglePlayRecording(url: URL) {
        if isPlayingRecording, currentlyPlayingRecordingURL == url {
            stopRecordingPlayback()
        } else {
            playRecording(url: url)
        }
    }

    func playRecording(url: URL) {
        stopBackingTrack()
        recordingPlayer?.stop()

        do {
            recordingPlayer = try AVAudioPlayer(contentsOf: url)
            recordingPlayer?.delegate = self
            recordingPlayer?.play()
            isPlayingRecording = true
            currentlyPlayingRecordingURL = url
        } catch {
            lastError = "Error playing recording: \(error.localizedDescription)"
        }
    }

    func stopRecordingPlayback() {
        recordingPlayer?.stop()
        isPlayingRecording = false
        currentlyPlayingRecordingURL = nil
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
            currentlyPlayingRecordingURL = nil
        } else if player == backingTrackPlayer {
            isPlayingBackingTrack = false
            isBackingTrackPaused = false
            stopTimer()
            currentTime = 0
        }
    }
}
