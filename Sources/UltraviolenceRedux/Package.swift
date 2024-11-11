// swift-tools-version: 6.0

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "NotSwiftUI",
    platforms: [.macOS(.v14)],
    products: [
        .library(
            name: "NotSwiftUI",
            targets: ["NotSwiftUI"]
        ),
        .executable(
            name: "NotSwiftUIClient",
            targets: ["NotSwiftUIClient"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/swiftlang/swift-syntax.git",
            from: "600.0.0-latest")
    ],
    targets: [
        .target(
            name: "NotSwiftUI",
            dependencies: ["NotSwiftUIMacros"]
        ),
        .macro(
            name: "NotSwiftUIMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .executableTarget(
            name: "NotSwiftUIClient", dependencies: ["NotSwiftUI"]
        ),
        .testTarget(
            name: "NotSwiftUITests",
            dependencies: [
                "NotSwiftUI",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")
            ]
        )
    ]
)
