// swift-tools-version: 6.0

import CompilerPluginSupport
import PackageDescription

public let package = Package(
    name: "Ultraviolence",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(name: "Ultraviolence", targets: ["Ultraviolence"]),
        .library(name: "Examples", targets: ["Examples"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0-latest")
    ],
    targets: [
        .target(name: "Ultraviolence", dependencies: ["UltraviolenceSupport"]),
        .target(name: "Examples", dependencies: ["Ultraviolence", "UltraviolenceSupport"], resources: [.copy("teapot.obj")]),
        .testTarget(name: "UltraviolenceTests", dependencies: ["Ultraviolence", "Examples", "UltraviolenceSupport"]),
        .executableTarget(name: "uvcli", dependencies: ["Ultraviolence", "Examples", "UltraviolenceSupport"]),
        .target(name: "UltraviolenceSupport", dependencies: ["UltraviolenceMacros"]),
        .macro(
            name: "UltraviolenceMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
