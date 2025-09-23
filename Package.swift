// swift-tools-version: 6.1

import CompilerPluginSupport
import PackageDescription

public let package = Package(
    name: "Ultraviolence",
    platforms: [
        .iOS("18.6"),
        .macOS("15.6"),
        .visionOS("2.6")
    ],
    products: [
        .library(name: "Ultraviolence", targets: ["Ultraviolence"]),
        .library(name: "UltraviolenceUI", targets: ["UltraviolenceUI"]),
        .library(name: "UltraviolenceSupport", targets: ["UltraviolenceSupport"]),
        .library(name: "UltraviolenceExamples", targets: ["UltraviolenceExamples"]),
        .library(name: "UltraviolenceSnapshotUI", targets: ["UltraviolenceSnapshotUI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0-latest"),
        .package(url: "https://github.com/schwa/MetalCompilerPlugin", from: "0.1.0"),
        .package(url: "https://github.com/apple/swift-collections", from: "1.2.0"),
        .package(url: "https://github.com/schwa/GeometryLite3D", branch: "main"),
        .package(url: "https://github.com/schwa/SwiftGLTF", branch: "main"),
        .package(url: "https://github.com/schwa/Panels", branch: "main"),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.0"),
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
                "ZIPFoundation"
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
        .target(
            name: "UltraviolenceExamples",
            dependencies: [
                "Ultraviolence",
                "UltraviolenceExampleShaders",
                "UltraviolenceUI",
                "GeometryLite3D",
                .product(name: "Collections", package: "swift-collections"),
                "MikkTSpace",
                .product(name: "SwiftGLTF", package: "SwiftGLTF"),
                "Panels",
            ],
            resources: [
                .copy("Resources/AppleEventVideo.mp4"),
                .copy("Resources/AppleLogoMask.png"),
                .copy("Resources/DJSI3956.JPG"),
                .copy("Resources/DSC_2595.JPG"),
                .copy("Resources/HD-Testcard-original.jpg"),
                .copy("Resources/IndoorEnvironmentHDRI013_1K-HDR.exr"),
                .copy("Resources/Samples"),
                .copy("Resources/teapot.obj"),
                .copy("Resources/4.2.03.heic"),
            ],
            swiftSettings: [
//                .defaultIsolation(nil)
            ]
        ),
        .target(
            name: "UltraviolenceExampleShaders",
            publicHeadersPath: ".",
            plugins: [
                .plugin(name: "MetalCompilerPlugin", package: "MetalCompilerPlugin")
            ]
        ),
        .testTarget(
            name: "UltraviolenceExamplesTests",
            dependencies: ["UltraviolenceExamples"]
        ),
        .target(
            name: "MikkTSpace",
            publicHeadersPath: ".",
        )
    ],
    swiftLanguageModes: [.v6]
)
