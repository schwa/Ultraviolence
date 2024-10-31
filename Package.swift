// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Ultraviolence",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "Ultraviolence", targets: ["Ultraviolence"]),
    ],
    targets: [
        .target(name: "Ultraviolence"),
        .testTarget(name: "UltraviolenceTests", dependencies: ["Ultraviolence"]),
        .executableTarget(name: "uvcli", dependencies: ["Ultraviolence"])
    ]
)
