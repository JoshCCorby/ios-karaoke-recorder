import SwiftUI

@main
struct VocalPracticeApp: App {
    init() {
        _ = AudioSessionManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
