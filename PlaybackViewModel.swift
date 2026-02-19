import Foundation
import AVFoundation

class PlaybackViewModel: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlayingBackingTrack = false
    @Published var isPlayingRecording = false
    @Published var duration: TimeInterval = 0
    @Published var currentTime: TimeInterval = 0
    
    var backingTrackPlayer: AVAudioPlayer?
    var recordingPlayer: AVAudioPlayer?
    
    private var timer: Timer?
    
    // Import backing track
    func loadBackingTrack(url: URL) {
        do {
            backingTrackPlayer = try AVAudioPlayer(contentsOf: url)
            backingTrackPlayer?.prepareToPlay()
            duration = backingTrackPlayer?.duration ?? 0
            print("Backing track loaded: \(url.lastPathComponent)")
        } catch {
            print("Error loading backing track: \(error)")
        }
    }
    
    func toggleBackingTrack() {
        guard let player = backingTrackPlayer else { return }
        
        if player.isPlaying {
            player.pause()
            isPlayingBackingTrack = false
            stopTimer()
        } else {
            player.play()
            isPlayingBackingTrack = true
            startTimer()
        }
    }
    
    func stopBackingTrack() {
        backingTrackPlayer?.stop()
        backingTrackPlayer?.currentTime = 0
        isPlayingBackingTrack = false
        stopTimer()
        currentTime = 0
    }
    
    // Play a recorded take
    func playRecording(url: URL) {
        // Stop backing track first if playing? Or mix?
        // For "Simple playback of saved takes", usually imply solo playback, 
        // but simultaneous playback is the core feature *during* recording.
        // During review/listening back, we likely just want to hear the take.
        
        do {
            recordingPlayer = try AVAudioPlayer(contentsOf: url)
            recordingPlayer?.delegate = self
            recordingPlayer?.play()
            isPlayingRecording = true
        } catch {
            print("Error playing recording: \(error)")
        }
    }
    
    func stopRecordingPlayback() {
        recordingPlayer?.stop()
        isPlayingRecording = false
    }
    
    // MARK: - Timer
    
    private func startTimer() {
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
    
    // MARK: - AVAudioPlayerDelegate
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if player == recordingPlayer {
            isPlayingRecording = false
        } else if player == backingTrackPlayer {
            isPlayingBackingTrack = false
            stopTimer()
            currentTime = 0
        }
    }
}
