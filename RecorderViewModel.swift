import Foundation
import AVFoundation

class RecorderViewModel: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var isRecording = false
    @Published var isPaused = false
    @Published var recordingTime: TimeInterval = 0
    @Published var audioLevel: Float = 0.0
    @Published var recordings: [URL] = []
    @Published var micPermissionGranted = false
    @Published var micPermissionDenied = false
    @Published var lastError: String?

    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private var recordingURL: URL?

    override init() {
        super.init()
        refreshMicPermissionStatus()
    }

    func refreshMicPermissionStatus() {
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .granted:
                micPermissionGranted = true
                micPermissionDenied = false
            case .denied:
                micPermissionGranted = false
                micPermissionDenied = true
            case .undetermined:
                micPermissionGranted = false
                micPermissionDenied = false
            @unknown default:
                micPermissionGranted = false
                micPermissionDenied = false
            }
            return
        }

        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            micPermissionGranted = true
            micPermissionDenied = false
        case .denied:
            micPermissionGranted = false
            micPermissionDenied = true
        case .undetermined:
            micPermissionGranted = false
            micPermissionDenied = false
        @unknown default:
            micPermissionGranted = false
            micPermissionDenied = false
        }
    }

    func requestMicPermission(completion: @escaping (Bool) -> Void) {
        refreshMicPermissionStatus()
        if micPermissionGranted {
            completion(true)
            return
        }
        if micPermissionDenied {
            lastError = "Microphone access was denied. Enable it in Settings to record."
            completion(false)
            return
        }

        let handleResponse: (Bool) -> Void = { [weak self] granted in
            DispatchQueue.main.async {
                self?.refreshMicPermissionStatus()
                if !granted {
                    self?.lastError = "Microphone access is required to record your vocal take."
                }
                completion(granted)
            }
        }

        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission(completionHandler: handleResponse)
            return
        }

        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            handleResponse(granted)
        }
    }

    @discardableResult
    func startRecording() -> Bool {
        lastError = nil

        let fileName = "recording-\(Date().timeIntervalSince1970).m4a"
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let fileURL = paths[0].appendingPathComponent(fileName)
        recordingURL = fileURL

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

            guard audioRecorder?.record() == true else {
                lastError = "Could not start recording. Check microphone access and try again."
                return false
            }

            isRecording = true
            isPaused = false
            startTimer()
            return true
        } catch {
            lastError = "Error setting up recorder: \(error.localizedDescription)"
            return false
        }
    }

    func pauseRecording() {
        guard isRecording, !isPaused else { return }
        audioRecorder?.pause()
        isPaused = true
        isRecording = false
        stopTimer()
        audioLevel = 0.0
    }

    func resumeRecording() -> Bool {
        guard let recorder = audioRecorder, isPaused else { return false }
        guard recorder.record() else {
            lastError = "Could not resume recording."
            return false
        }
        isPaused = false
        isRecording = true
        startTimer()
        return true
    }

    func stopRecording() {
        audioRecorder?.stop()
        isRecording = false
        isPaused = false
        stopTimer()
        audioLevel = 0.0
        fetchRecordings()
    }

    func fetchRecordings() {
        let fileManager = FileManager.default
        let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let directoryContents = try? fileManager.contentsOfDirectory(
            at: documentDirectory,
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        )

        guard let contents = directoryContents else { return }

        recordings = contents
            .filter { $0.pathExtension == "m4a" }
            .sorted { lhs, rhs in
                let lhsDate = (try? lhs.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                let rhsDate = (try? rhs.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                return lhsDate > rhsDate
            }
    }

    @discardableResult
    func deleteRecording(at url: URL) -> Bool {
        do {
            try FileManager.default.removeItem(at: url)
            recordings.removeAll { $0 == url }
            return true
        } catch {
            lastError = "Could not delete recording: \(error.localizedDescription)"
            return false
        }
    }

    func deleteRecordings(at offsets: IndexSet) {
        let urls = offsets.map { recordings[$0] }
        urls.forEach { deleteRecording(at: $0) }
    }

    private func startTimer() {
        recordingTime = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.recordingTime = self.audioRecorder?.currentTime ?? self.recordingTime
            self.updateMeters()
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func updateMeters() {
        audioRecorder?.updateMeters()
        let power = audioRecorder?.averagePower(forChannel: 0) ?? -160
        audioLevel = RecorderViewModel.normalizedLevel(fromPower: power)
    }

    /// Maps an `AVAudioRecorder` average power reading (in dBFS, roughly -160...0)
    /// to a 0...1 level suitable for a meter. Pure for unit testing.
    static func normalizedLevel(fromPower power: Float) -> Float {
        let floorDb: Float = -60
        guard power.isFinite else { return 0 }
        let clamped = min(0, max(floorDb, power))
        return (clamped - floorDb) / -floorDb
    }

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            lastError = "Recording finished unsuccessfully."
        }
    }
}
