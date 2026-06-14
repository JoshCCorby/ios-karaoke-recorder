import AVFoundation
import Combine

enum InterruptionPhase: Equatable {
    case none
    case began
    case ended(shouldResume: Bool)
}

class AudioSessionManager: ObservableObject {
    static let shared = AudioSessionManager()

    @Published var isAudioSessionActive = false
    @Published var interruptionPhase: InterruptionPhase = .none
    @Published var routeChangeReason: AVAudioSession.RouteChangeReason?

    /// - Parameter autoConfigure: when `false`, skips real `AVAudioSession`
    ///   configuration and notification registration. Used by unit tests to
    ///   create an isolated instance and drive the published state directly.
    init(autoConfigure: Bool = true) {
        guard autoConfigure else { return }
        setupAudioSession()
        setupNotifications()
    }

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .playAndRecord,
                mode: .default,
                options: [.defaultToSpeaker, .allowBluetooth, .allowBluetoothA2DP, .allowAirPlay]
            )
            try session.setActive(true)
            isAudioSessionActive = true
        } catch {
            print("Failed to configure AudioSession: \(error)")
            isAudioSessionActive = false
        }
    }

    func reactivateSession() throws {
        try AVAudioSession.sharedInstance().setActive(true)
        DispatchQueue.main.async {
            self.isAudioSessionActive = true
        }
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }

    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            DispatchQueue.main.async {
                self.isAudioSessionActive = false
                self.interruptionPhase = .began
            }
        case .ended:
            var shouldResume = false
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                shouldResume = options.contains(.shouldResume)
            }
            if shouldResume {
                do {
                    try reactivateSession()
                } catch {
                    print("Failed to reactivate session after interruption: \(error)")
                }
            }
            DispatchQueue.main.async {
                self.interruptionPhase = .ended(shouldResume: shouldResume)
            }
        @unknown default:
            break
        }
    }

    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }

        DispatchQueue.main.async {
            self.routeChangeReason = reason
        }
    }

    func duplicateAudioToSpeaker() {
        do {
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
        } catch {
            print("Failed to override output to speaker: \(error)")
        }
    }
}
