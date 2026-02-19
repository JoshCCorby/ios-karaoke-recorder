import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var recorderVM = RecorderViewModel()
    @StateObject private var playbackVM = PlaybackViewModel()
    @State private var showingFileImporter = false
    
    var body: some View {
        VStack(spacing: 30) {
            // Header
            Text("Vocal Practice")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)
            
            // Backing Track Section
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
                    .disabled(playbackVM.duration == 0)
                    
                    VStack(alignment: .leading) {
                        Text(playbackVM.backingTrackPlayer?.url?.lastPathComponent ?? "No Track Loaded")
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
            
            Spacer()
            
            // Recording Controls
            VStack(spacing: 20) {
                Text(formatTime(recorderVM.recordingTime))
                    .font(.system(size: 60, weight: .light, design: .monospaced))
                
                // VU Meter Visualization (Simple Bar)
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
                
                Button(action: {
                    if recorderVM.isRecording {
                        recorderVM.stopRecording()
                        playbackVM.stopBackingTrack()
                    } else {
                        recorderVM.startRecording()
                        if playbackVM.duration > 0 {
                            playbackVM.toggleBackingTrack()
                        }
                    }
                }) {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                            .frame(width: 80, height: 80)
                        
                        if recorderVM.isRecording {
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
            }
            
            Spacer()
            
            // Recordings List (Placeholder for now)
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
                }
            }
        }
        .fileImporter(isPresented: $showingFileImporter, allowedContentTypes: [.audio]) { result in
            switch result {
            case .success(let url):
                // Access security scoped resource if needed, but for simple import copy it
                 if url.startAccessingSecurityScopedResource() {
                     defer { url.stopAccessingSecurityScopedResource() }
                     playbackVM.loadBackingTrack(url: url)
                 }
            case .failure(let error):
                print("Import failed: \(error)")
            }
        }
    }
    
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
