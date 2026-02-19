import AVFoundation

class AudioSessionManager: ObservableObject {
    static let shared = AudioSessionManager()
    
    @Published var isAudioSessionActive = false
    
    private init() {
        setupAudioSession()
        setupNotifications()
    }
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth, .allowAirPlay])
            try session.setActive(true)
            isAudioSessionActive = true
            print("AudioSession configured successfully")
        } catch {
            print("Failed to configure AudioSession: \(error)")
            isAudioSessionActive = false
        }
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleInterruption),
                                               name: AVAudioSession.interruptionNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleRouteChange),
                                               name: AVAudioSession.routeChangeNotification,
                                               object: nil)
    }
    
    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            print("Audio Session Interruption began")
            // Pause playback/recording handled by view models observing this or via direct coordination
        case .ended:
            print("Audio Session Interruption ended")
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                     print("Should resume audio")
                }
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
        
        print("Audio Route changed: \(reason)")
    }
    
    func duplicateAudioToSpeaker() {
         do {
             try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
         } catch {
             print("Failed to override output to speaker: \(error)")
         }
    }
}
