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
        .library(name: "UltraviolenceUI", targets: ["UltraviolenceUI"]),
        .library(name: "UltraviolenceRedux", targets: ["UltraviolenceRedux"])
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.0-latest")
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
            resources: [
                .copy("teapot.obj")
            ]
        ),
        .target(
            name: "UltraviolenceSupport",
            dependencies: [
                "UltraviolenceMacros"
            ]
        ),
        .target(
            name: "UltraviolenceUI",
            dependencies: [
                "Ultraviolence",
                "UltraviolenceSupport"
            ]
        ),
        .executableTarget(
            name: "uvcli",
            dependencies: [
                "Ultraviolence",
                "UltraviolenceExamples",
                "UltraviolenceSupport"
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
                "UltraviolenceSupport"
            ]
        ),

        .target(
            name: "UltraviolenceRedux",
            dependencies: [
                "UltraviolenceSupport"
            ]
        ),
        .executableTarget(
            name: "uvreduxcli",
            dependencies: [
                "UltraviolenceRedux",
                "UltraviolenceSupport"
            ]
        ),
        .testTarget(
            name: "UltraviolenceReduxTests",
            dependencies: [
                "UltraviolenceRedux",
                "UltraviolenceSupport",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
