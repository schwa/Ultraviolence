// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Ultraviolence",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "Ultraviolence", targets: ["Ultraviolence"]),
        .library(name: "Examples", targets: ["Examples"]),
    ],
    targets: [
        .target(name: "Ultraviolence", dependencies: ["BaseSupport"]),
        .target(name: "Examples", dependencies: ["Ultraviolence", "BaseSupport"]),
        .testTarget(name: "UltraviolenceTests", dependencies: ["Ultraviolence", "Examples", "BaseSupport"]),
        .executableTarget(name: "uvcli", dependencies: ["Ultraviolence", "Examples", "BaseSupport"]),
        .target(name: "BaseSupport"),
    ],
    swiftLanguageVersions: [.v6]
)
