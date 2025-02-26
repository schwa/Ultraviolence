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
        .library(name: "UltraviolenceExamples", targets: ["UltraviolenceExamples"]),
        .library(name: "UltraviolenceSupport", targets: ["UltraviolenceSupport"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0-latest"),
        .package(url: "https://github.com/schwa/MetalCompilerPlugin", branch: "main"),
    ],
    targets: [
        .target(
            name: "Ultraviolence",
            dependencies: [
                "UltraviolenceSupport"
            ]
        ),
        .target(
            name: "UltraviolenceExamples",
            dependencies: [
                "Ultraviolence",
                "UltraviolenceSupport"
            ],
            exclude: [
                "EdgeDetectionKernel.metal",
                "FlatShader.metal",
                "LambertianShader.metal",
                "RedTriangle.metal",
                "CheckerboardKernel.metal"
            ],
            resources: [
                .copy("teapot.obj"),
                .copy("HD-Testcard-original.jpg")
            ],
            plugins: [
                .plugin(name: "MetalCompilerPlugin", package: "MetalCompilerPlugin")
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
                "UltraviolenceExamples",
                "UltraviolenceSupport",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")
            ],
            resources: [
                .copy("Golden Images")
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
