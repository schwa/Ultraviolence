// swift-tools-version: 6.2

import CompilerPluginSupport
import PackageDescription

public let package = Package(
    name: "Ultraviolence",
    platforms: [
        .iOS("18.2"),
        .macOS("15.2")
    ],
    products: [
        .library(name: "Ultraviolence", targets: ["Ultraviolence"]),
        .library(name: "UltraviolenceUI", targets: ["UltraviolenceUI"]),
        .library(name: "UltraviolenceSupport", targets: ["UltraviolenceSupport"]),
        .library(name: "UltraviolenceExamples", targets: ["UltraviolenceExamples"]),
        .library(name: "UltraviolenceGaussianSplats", targets: ["UltraviolenceGaussianSplats"]),
        .library(name: "UltraviolenceKit", targets: ["UltraviolenceKit"]),
        .executable(name: "UltraviolenceCLI", targets: ["UltraviolenceCLI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0-latest"),
        .package(url: "https://github.com/schwa/MetalCompilerPlugin", from: "0.1.0"),
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "Ultraviolence",
            dependencies: [
                "UltraviolenceSupport",
            ]
        ),
        .target(
            name: "UltraviolenceUI",
            dependencies: [
                "Ultraviolence",
                "UltraviolenceSupport"
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
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")
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
                "UltraviolenceGaussianSplats",
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms")
            ],
            swiftSettings: [
                .defaultIsolation(nil)
            ]
        ),
        .target(
            name: "UltraviolenceExampleShaders",
            exclude: [
                "BlinnPhongShaders.metal",
                "FlatShader.metal"
            ],
            plugins: [
                .plugin(name: "MetalCompilerPlugin", package: "MetalCompilerPlugin")
            ]
        ),
        .executableTarget(
            name: "UltraviolenceCLI",
            dependencies: [
                "Ultraviolence",
                "UltraviolenceSupport",
                "UltraviolenceExamples"
            ],
            resources: [
                .copy("Teapot.usdz")
            ]
        ),
        .target(
            name: "GaussianSplatShaders",
            plugins: [
                .plugin(name: "MetalCompilerPlugin", package: "MetalCompilerPlugin")
            ]
        ),
        .target(
            name: "UltraviolenceGaussianSplats",
            dependencies: [
                "Ultraviolence",
                "UltraviolenceSupport",
                "GaussianSplatShaders",
                "UltraviolenceUI"
            ]
        ),
        .target(
            name: "UltraviolenceKit",
            dependencies: [
                "Ultraviolence",
                "UltraviolenceSupport"
            ]
        ),
        .testTarget(
            name: "UltraviolenceExamplesTests",
            dependencies: ["UltraviolenceExamples"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
