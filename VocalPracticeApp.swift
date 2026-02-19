import SwiftUI

@main
struct VocalPracticeApp: App {
    // Initialize AudioSessionManager on app launch
    init() {
        _ = AudioSessionManager.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
