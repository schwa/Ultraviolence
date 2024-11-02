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
        .target(name: "Ultraviolence"),
        .target(name: "Examples", dependencies: ["Ultraviolence"]),
        .testTarget(name: "UltraviolenceTests", dependencies: ["Ultraviolence"]),
        .executableTarget(name: "uvcli", dependencies: ["Ultraviolence"])
    ]
)
