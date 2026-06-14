// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VocalPractice",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .executable(name: "VocalPractice", targets: ["VocalPractice"])
    ],
    targets: [
        .executableTarget(
            name: "VocalPractice",
            path: ".",
            exclude: [
                "README.md",
                "LICENSE",
                "Voice Memos",
                "web-preview",
                "Assets.xcassets",
                "Info.plist",
                "VocalPractice.xcodeproj"
            ],
            sources: [
                "VocalPracticeApp.swift",
                "ContentView.swift",
                "RecorderViewModel.swift",
                "PlaybackViewModel.swift",
                "AudioSessionManager.swift",
                "KaraokeTakeCoordinator.swift"
            ]
        )
    ]
)
