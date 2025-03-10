// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "UltraviolenceExamples",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(name: "UltraviolenceExamples", targets: ["UltraviolenceExamples"])
    ],
    dependencies: [
        .package(name: "Ultraviolence", path: "../../.."),
        .package(url: "https://github.com/schwa/MetalCompilerPlugin", branch: "main")
    ],
    targets: [
        .target(
            name: "UltraviolenceExamples",
            dependencies: [
                "Ultraviolence",
                "UltraviolenceExampleShaders"
            ],
            exclude: [
                "EdgeDetectionKernel.metal",
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
            name: "UltraviolenceExampleShaders",
            exclude: [
                "BlinnPhongShaders.metal",
                "FlatShader.metal"
            ],
            plugins: [
                .plugin(name: "MetalCompilerPlugin", package: "MetalCompilerPlugin")
            ]
        ),
        .testTarget(
            name: "UltraviolenceExamplesTests",
            dependencies: ["UltraviolenceExamples"]
        )
    ]
)
