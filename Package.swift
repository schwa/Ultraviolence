// swift-tools-version: 6.1

import CompilerPluginSupport
import PackageDescription

public let package = Package(
    name: "Ultraviolence",
    platforms: [
        .iOS("18.5"),
        .macOS("15.5"),
        .visionOS("2.5")
    ],
    products: [
        .library(name: "Ultraviolence", targets: ["Ultraviolence"]),
        .library(name: "UltraviolenceUI", targets: ["UltraviolenceUI"]),
        .library(name: "UltraviolenceSupport", targets: ["UltraviolenceSupport"]),
        .library(name: "UltraviolenceSnapshotUI", targets: ["UltraviolenceSnapshotUI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0-latest"),
//        .package(url: "https://github.com/schwa/MetalCompilerPlugin", from: "0.1.0"),
        .package(url: "https://github.com/schwa/GeometryLite3D", branch: "main"),
    ],
    targets: [
        .target(
            name: "Ultraviolence",
            dependencies: [
                "UltraviolenceSupport"
            ]
        ),
        .target(
            name: "UltraviolenceUI",
            dependencies: [
                "Ultraviolence",
                "UltraviolenceSupport",
            ]
        ),
        .target(
            name: "UltraviolenceSnapshotUI",
            dependencies: [
                "Ultraviolence",
                "UltraviolenceUI"
            ]
        ),
        .target(
            name: "UltraviolenceSupport",
            dependencies: [
                "UltraviolenceMacros"
            ]
        ),
        .macro(
            name: "UltraviolenceMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .testTarget(
            name: "UltraviolenceTests",
            dependencies: [
                "Ultraviolence",
                "UltraviolenceUI",
                "UltraviolenceSupport",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                "GeometryLite3D",
            ],
            resources: [
                .copy("Golden Images")
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
