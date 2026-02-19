// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

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
                "Voice Memos"
            ],
            sources: [
                "VocalPracticeApp.swift",
                "ContentView.swift",
                "RecorderViewModel.swift",
                "PlaybackViewModel.swift",
                "AudioSessionManager.swift"
            ]
        )
    ]
)
