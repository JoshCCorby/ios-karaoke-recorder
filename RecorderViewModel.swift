import Foundation
import AVFoundation

class RecorderViewModel: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var isRecording = false
    @Published var recordingTime: TimeInterval = 0
    @Published var audioLevel: Float = 0.0
    
    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    
    // Path where recordings are saved
    private var recordingURL: URL?
    
    override init() {
        super.init()
    }
    
    func startRecording() {
        // Ensure session is active
        // In a real app, you might want to coordinate this better with AudioSessionManager
        // but for now we assume AudioSessionManager has set up the shared session.
        
        let fileName = "recording-\(Date().timeIntervalSince1970).m4a"
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let fileURL = paths[0].appendingPathComponent(fileName)
        self.recordingURL = fileURL
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            
            if audioRecorder?.record() == true {
                isRecording = true
                startTimer()
                print("Recording started: \(fileURL)")
            } else {
                print("Failed to start recording")
            }
        } catch {
            print("Error setting up recorder: \(error)")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        stopTimer()
        audioLevel = 0.0
        print("Recording stopped")
        fetchRecordings()
    }
    
    // MARK: - File Management
    @Published var recordings: [URL] = []
    
    func fetchRecordings() {
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let directoryContents = try? fileManager.contentsOfDirectory(at: documentDirectory, includingPropertiesForKeys: nil)
        
        if let contents = directoryContents {
            recordings = contents.filter { $0.pathExtension == "m4a" }
            recordings.sort(by: { $0.lastPathComponent > $1.lastPathComponent }) // Sort by name (roughly date)
        }
    }
    
    // MARK: - Timer & Metering
    
    private func startTimer() {
        recordingTime = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.recordingTime += 0.1
            self.updateMeters()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateMeters() {
        audioRecorder?.updateMeters()
        // Initialize with a low value
        let power = audioRecorder?.averagePower(forChannel: 0) ?? -160
        // Normalize to 0-1 range for UI (assuming -60dB floor)
        let normalized = max(0, (power + 60) / 60)
        self.audioLevel = normalized
    }
    
    // MARK: - AVAudioRecorderDelegate
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            print("Recording finished unsuccessfully")
        }
    }
}
