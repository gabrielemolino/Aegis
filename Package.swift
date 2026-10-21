// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SentinelAI",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "SentinelAI", targets: ["SentinelAI"])
    ],
    targets: [
        .executableTarget(
            name: "SentinelAI",
            path: "Sources/SentinelAI"
        ),
        .testTarget(
            name: "SentinelAITests",
            dependencies: ["SentinelAI"],
            path: "Tests/SentinelAITests"
        )
    ]
)

