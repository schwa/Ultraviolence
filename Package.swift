// swift-tools-version: 6.0

import PackageDescription

public let package = Package(
    name: "Ultraviolence",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(name: "Ultraviolence", targets: ["Ultraviolence"]),
        .library(name: "Examples", targets: ["Examples"])
    ],
    targets: [
        .target(name: "Ultraviolence", dependencies: ["UltraviolenceSupport"]),
        .target(name: "Examples", dependencies: ["Ultraviolence", "UltraviolenceSupport"], resources: [.copy("teapot.obj")]),
        .testTarget(name: "UltraviolenceTests", dependencies: ["Ultraviolence", "Examples", "UltraviolenceSupport"]),
        .executableTarget(name: "uvcli", dependencies: ["Ultraviolence", "Examples", "UltraviolenceSupport"]),
        .target(name: "UltraviolenceSupport")
    ],
    swiftLanguageModes: [.v6]
)
