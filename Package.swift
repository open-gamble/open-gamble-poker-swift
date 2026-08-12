// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OpenGamblePoker",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(name: "OpenGamblePoker", targets: ["OpenGamblePoker"])
    ],
    targets: [
        .target(
            name: "OpenGamblePoker",
            path: "OpenGamblePoker",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "OpenGamblePokerTests",
            dependencies: ["OpenGamblePoker"],
            path: "OpenGamblePokerTests"
        )
    ]
)
