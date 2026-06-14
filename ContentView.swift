import SwiftUI
import AVFoundation
import UIKit

struct ContentView: View {
    @StateObject private var coordinator = KaraokeTakeCoordinator()
    @State private var showingFileImporter = false
    @State private var showingMicDeniedAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""

    private var recorderVM: RecorderViewModel { coordinator.recorderVM }
    private var playbackVM: PlaybackViewModel { coordinator.playbackVM }

    var body: some View {
        VStack(spacing: 30) {
            Text("Vocal Practice")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)

            VStack {
                Text("Backing Track")
                    .font(.headline)
                    .foregroundColor(.gray)

                HStack {
                    Button(action: {
                        playbackVM.toggleBackingTrack()
                    }) {
                        Image(systemName: playbackVM.isPlayingBackingTrack ? "pause.circle.fill" : "play.circle.fill")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.blue)
                    }
                    .disabled(playbackVM.duration == 0 || coordinator.isTakeActive)

                    VStack(alignment: .leading) {
                        Text(playbackVM.backingTrackName ?? "No Track Loaded")
                            .lineLimit(1)
                        if playbackVM.duration > 0 {
                            Text("\(formatTime(playbackVM.currentTime)) / \(formatTime(playbackVM.duration))")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)

                Button("Import Track") {
                    showingFileImporter = true
                }
                .padding(.top, 5)
            }
            .padding(.horizontal)

            if coordinator.isTakePaused {
                Text(pauseStatusText)
                    .font(.subheadline)
                    .foregroundColor(.orange)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            VStack(spacing: 20) {
                Text(formatTime(recorderVM.recordingTime))
                    .font(.system(size: 60, weight: .light, design: .monospaced))

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 8)
                            .cornerRadius(4)

                        Rectangle()
                            .fill(recorderVM.audioLevel > 0.8 ? Color.red : Color.green)
                            .frame(width: geometry.size.width * CGFloat(recorderVM.audioLevel), height: 8)
                            .cornerRadius(4)
                            .animation(.linear(duration: 0.1), value: recorderVM.audioLevel)
                    }
                }
                .frame(height: 8)
                .padding(.horizontal, 40)

                HStack(spacing: 24) {
                    if coordinator.isTakePaused {
                        Button(action: {
                            coordinator.resumeTake()
                        }) {
                            Text("Resume")
                                .font(.headline)
                                .foregroundColor(.blue)
                        }

                        Button(action: {
                            coordinator.stopTake()
                        }) {
                            Text("Stop")
                                .font(.headline)
                                .foregroundColor(.red)
                        }
                    } else {
                        Button(action: {
                            if coordinator.isTakeActive {
                                coordinator.stopTake()
                            } else {
                                coordinator.startTake()
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                                    .frame(width: 80, height: 80)

                                if coordinator.isTakeActive {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.red)
                                        .frame(width: 30, height: 30)
                                } else {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 60, height: 60)
                                }
                            }
                        }
                        .disabled(!coordinator.canStartTake && !coordinator.isTakeActive)
                    }
                }
            }

            Spacer()

            VStack(alignment: .leading) {
                Text("Recent Takes")
                    .font(.headline)
                    .padding(.horizontal)

                List {
                    ForEach(recorderVM.recordings, id: \.self) { url in
                        HStack {
                            Text(url.lastPathComponent)
                                .font(.caption)
                            Spacer()
                            Button(action: {
                                playbackVM.playRecording(url: url)
                            }) {
                                Image(systemName: "play.circle")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    if recorderVM.recordings.isEmpty {
                        Text("No recordings yet")
                            .foregroundColor(.gray)
                    }
                }
                .listStyle(.plain)
                .frame(height: 150)
                .onAppear {
                    recorderVM.fetchRecordings()
                    recorderVM.refreshMicPermissionStatus()
                }
            }
        }
        .fileImporter(isPresented: $showingFileImporter, allowedContentTypes: [.audio]) { result in
            switch result {
            case .success(let url):
                coordinator.importBackingTrack(from: url, hasSecurityScope: true)
            case .failure(let error):
                errorMessage = "Import failed: \(error.localizedDescription)"
                showingErrorAlert = true
            }
        }
        .onChange(of: recorderVM.micPermissionDenied) { denied in
            if denied {
                showingMicDeniedAlert = true
            }
        }
        .onChange(of: coordinator.lastError) { error in
            guard let error else { return }
            errorMessage = error
            showingErrorAlert = true
        }
        .onChange(of: playbackVM.lastError) { error in
            guard let error else { return }
            errorMessage = error
            showingErrorAlert = true
        }
        .onChange(of: recorderVM.lastError) { error in
            guard let error else { return }
            errorMessage = error
            showingErrorAlert = true
        }
        .alert("Microphone Access Required", isPresented: $showingMicDeniedAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enable microphone access in Settings to record vocal takes.")
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private var pauseStatusText: String {
        switch coordinator.pauseReason {
        case .interruption:
            return "Take paused — audio was interrupted (call, Siri, etc.). Tap Resume or Stop."
        case .headphonesRemoved:
            return "Take paused — headphones were removed. Tap Resume or Stop."
        case .none:
            return "Take paused. Tap Resume or Stop."
        }
    }

    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
