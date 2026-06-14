import AVFoundation
import Combine
import Foundation

enum TakePauseReason: Equatable {
    case interruption
    case headphonesRemoved
}

class KaraokeTakeCoordinator: ObservableObject {
    let recorderVM = RecorderViewModel()
    let playbackVM = PlaybackViewModel()
    let sessionManager: AudioSessionManager

    @Published var isTakeActive = false
    @Published var isTakePaused = false
    @Published var pauseReason: TakePauseReason?
    @Published var lastError: String?

    private var cancellables = Set<AnyCancellable>()

    init(sessionManager: AudioSessionManager = .shared) {
        self.sessionManager = sessionManager
        setupObservers()

        recorderVM.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
        playbackVM.objectWillChange
            .sink { [weak self] in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    var canStartTake: Bool {
        sessionManager.isAudioSessionActive && !recorderVM.micPermissionDenied
    }

    func startTake() {
        lastError = nil

        guard sessionManager.isAudioSessionActive else {
            lastError = "Audio session is not active. Try again after any phone call or Siri interruption ends."
            return
        }

        recorderVM.requestMicPermission { [weak self] granted in
            guard let self = self else { return }
            guard granted else {
                self.lastError = self.recorderVM.lastError
                return
            }

            guard self.recorderVM.startRecording() else {
                self.lastError = self.recorderVM.lastError
                return
            }

            self.isTakeActive = true
            self.isTakePaused = false
            self.pauseReason = nil

            if self.playbackVM.duration > 0 {
                self.playbackVM.toggleBackingTrack()
            }
        }
    }

    func stopTake() {
        recorderVM.stopRecording()
        playbackVM.stopBackingTrack()
        isTakeActive = false
        isTakePaused = false
        pauseReason = nil
    }

    func pauseTake(reason: TakePauseReason) {
        guard isTakeActive, !isTakePaused else { return }

        recorderVM.pauseRecording()
        playbackVM.pauseBackingTrack()
        isTakeActive = false
        isTakePaused = true
        pauseReason = reason
    }

    func resumeTake() {
        guard isTakePaused else { return }

        do {
            if !sessionManager.isAudioSessionActive {
                try sessionManager.reactivateSession()
            }
        } catch {
            lastError = "Could not reactivate audio session: \(error.localizedDescription)"
            return
        }

        guard recorderVM.resumeRecording() else {
            lastError = recorderVM.lastError
            return
        }

        playbackVM.resumeBackingTrack()
        isTakeActive = true
        isTakePaused = false
        pauseReason = nil
    }

    func importBackingTrack(from url: URL, hasSecurityScope: Bool) {
        lastError = nil

        let didStartAccess = hasSecurityScope ? url.startAccessingSecurityScopedResource() : true
        defer {
            if hasSecurityScope, didStartAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        guard didStartAccess else {
            lastError = "Could not access the selected file. Try importing again."
            return
        }

        do {
            try playbackVM.importBackingTrack(from: url)
        } catch {
            lastError = "Import failed: \(error.localizedDescription)"
        }
    }

    private func setupObservers() {
        sessionManager.$interruptionPhase
            .receive(on: DispatchQueue.main)
            .sink { [weak self] phase in
                guard let self = self else { return }
                switch phase {
                case .began:
                    if self.isTakeActive {
                        self.pauseTake(reason: .interruption)
                    }
                case .ended(let shouldResume):
                    if shouldResume, self.isTakePaused, self.pauseReason == .interruption {
                        self.resumeTake()
                    }
                case .none:
                    break
                }
            }
            .store(in: &cancellables)

        sessionManager.$routeChangeReason
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] reason in
                guard let self = self else { return }
                if reason == .oldDeviceUnavailable, self.isTakeActive {
                    self.pauseTake(reason: .headphonesRemoved)
                }
            }
            .store(in: &cancellables)
    }
}
