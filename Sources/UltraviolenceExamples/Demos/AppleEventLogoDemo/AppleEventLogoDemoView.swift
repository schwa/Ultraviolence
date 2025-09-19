import AVFoundation
import MetalKit
import simd
import SwiftUI
import Ultraviolence
import UltraviolenceSupport
import UltraviolenceUI

public struct AppleEventLogoDemoView: View {
    @State
    private var device = _MTLCreateSystemDefaultDevice()

    @State
    private var heatTextures: [MTLTexture] = []

    @State
    private var coloredTexture: MTLTexture?

    @State
    private var gradientTexture: MTLTexture?

    @State
    private var maskTexture: MTLTexture?

    @State
    private var finalTexture: MTLTexture?

    @State
    private var offscreenTexture: MTLTexture?

    @State
    private var upscaledTexture: MTLTexture?

    @StateObject
    private var videoPlayer = VideoTexturePipeline(device: _MTLCreateSystemDefaultDevice())

    @State
    private var currentTextureIndex = 0

    @State
    private var heatParameters = HeatParameters(radius: 30)

    @State
    private var currentHeat: Float = 0

    @State
    private var debugMousePosition: SIMD2<Float> = .zero

    @State
    private var size: CGSize = .zero

    @State
    private var shaderLibrary = try! ShaderLibrary(bundle: .ultraviolenceExampleShaders().orFatalError(), namespace: "AppleEventLogoShaders")

    public init() {
    }

    public var body: some View {
        VStack {
            TimelineView(.animation) { timeline in
                RenderView { _, _ in
                    try ComputePass {
                        if heatTextures.count == 2 {
                            let previousTexture = heatTextures[currentTextureIndex]
                            let currentTexture = heatTextures[1 - currentTextureIndex]

                            try ComputePipeline(computeKernel: try shaderLibrary.heatup) {
                                try ComputeDispatch(threadsPerGrid: MTLSize(width: 256, height: 256, depth: 1), threadsPerThreadgroup: MTLSize(width: 16, height: 16, depth: 1))
                                    .parameter("previousTexture", texture: previousTexture)
                                    .parameter("currentTexture", texture: currentTexture)
                                    .parameter("heatParameters", value: heatParameters)
                            }
                        }
                    }
                    // Color remap compute pass
                    try ComputePass {
                        if heatTextures.count == 2, let coloredTexture, let gradientTexture, let maskTexture, let videoTexture = videoPlayer.currentTexture {
                            ColorRemapComputePipeline(inputTexture: heatTextures[1 - currentTextureIndex], outputTexture: coloredTexture, gradientTexture: gradientTexture, maskTexture: maskTexture, videoTexture: videoTexture, power: 0.8)
                        }
                    }
                    // Blend thermal with video
                    try ComputePass {
                        if let coloredTexture, let finalTexture {
                            ThermalVideoBlendPipeline(thermalTexture: coloredTexture, videoTexture: videoPlayer.currentTexture, heatTexture: heatTextures[1 - currentTextureIndex], outputTexture: finalTexture, videoBlendAmount: 0.7)
                        }
                    }
                    // Render the final blended result
                    #if canImport(MetalFX)
                    if let finalTexture, let offscreenTexture, let upscaledTexture {
                        // Render to offscreen texture first at 256x256
                        try RenderPass {
                            try TextureBillboardPipeline(specifier: .texture2D(finalTexture))
                        }
                        .renderPassDescriptorModifier { descriptor in
                            descriptor.colorAttachments[0].texture = offscreenTexture
                        }

                        // Upscale using MetalFX from 256x256 to 512x512
                        MetalFXSpatial(inputTexture: offscreenTexture, outputTexture: upscaledTexture)

                        // Final render of upscaled texture at 512x512
                        try RenderPass {
                            try TextureBillboardPipeline(specifier: .texture2D(upscaledTexture))
                        }
                    }
                    #else
                    try RenderPass {
                        if let finalTexture {
                            try TextureBillboardPipeline(texture: finalTexture)
                        }
                    }
                    #endif
                }
                .frame(width: 512, height: 512)
                .aspectRatio(1.0, contentMode: .fit)
                .onGeometryChange(for: CGSize.self, of: \.size) { newSize in
                    size = newSize
                }

                #if os(macOS)
                .onContinuousHover { phase in
                    switch phase {
                    case .active(let location):
                        // Normalize position using the actual size
                        let normalizedX = Float(location.x / size.width)
                        let normalizedY = Float(location.y / size.height)
                        let normalizedPosition = SIMD2<Float>(normalizedX, normalizedY)

                        // Calculate delta from previous position
                        let delta = normalizedPosition - heatParameters.mousePosition

                        heatParameters.mousePosition = normalizedPosition
                        heatParameters.mouseDirection = delta
                        debugMousePosition = normalizedPosition

                        // Calculate heat based on movement
                        let movementSpeed = simd_length(delta)
                        if movementSpeed > 0.001 {
                            currentHeat = min(currentHeat + movementSpeed * 5.0, 1.3)
                        }

                        // Always interacting when hovering
                        heatParameters.isInteracting = 1.0
                    case .ended:
                        heatParameters.isInteracting = 0.0
                    }
                }
                #endif
                .onChange(of: timeline.date) {
                    // Apply decay every frame
                    currentHeat *= 0.95
                    if currentHeat < 0.001 {
                        currentHeat = 0
                    }
                    heatParameters.heatIntensity = currentHeat

                    // Swap textures for next frame
                    currentTextureIndex = 1 - currentTextureIndex
                }
            }
            .task {
                do {
                    // Create heat textures for ping-ponging
                    let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba16Float, width: 256, height: 256, mipmapped: false)
                    textureDescriptor.usage = [.shaderRead, .shaderWrite]
                    heatTextures = try (0..<2).map { index in
                        let texture = try device.makeTexture(descriptor: textureDescriptor).orThrow(.resourceCreationFailure("Heat texture"))
                        texture.label = "Heat Texture \(index)"
                        return texture
                    }

                    // Create colored output texture
                    let colorDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: 256, height: 256, mipmapped: false)
                    colorDescriptor.usage = [.shaderRead, .shaderWrite]
                    coloredTexture = try device.makeTexture(descriptor: colorDescriptor).orThrow(.resourceCreationFailure("Colored texture"))
                    coloredTexture?.label = "Colored Output Texture"

                    // Create final blended output texture
                    finalTexture = try device.makeTexture(descriptor: colorDescriptor).orThrow(.resourceCreationFailure("Final texture"))
                    finalTexture?.label = "Final Blended Texture"

                    #if canImport(MetalFX)
                    // Create offscreen texture for rendering at 256x256
                    let offscreenDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: 256, height: 256, mipmapped: false)
                    offscreenDescriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
                    offscreenTexture = try device.makeTexture(descriptor: offscreenDescriptor).orThrow(.resourceCreationFailure("Offscreen texture"))
                    offscreenTexture?.label = "Offscreen Texture"

                    // Create upscaled texture at 512x512 (2x upscale)
                    let upscaledDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: 512, height: 512, mipmapped: false)
                    upscaledDescriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
                    upscaledDescriptor.storageMode = .private
                    upscaledTexture = try device.makeTexture(descriptor: upscaledDescriptor).orThrow(.resourceCreationFailure("Upscaled texture"))
                    upscaledTexture?.label = "Upscaled Texture"
                    #endif

                    // Create thermal gradient texture
                    gradientTexture = try GradientTextureGenerator.createThermalGradient(device: device)

                    // Load Apple logo mask texture from bundle
                    let textureLoader = MTKTextureLoader(device: device)
                    guard let maskURL = Bundle.module.url(forResource: "AppleLogoMask", withExtension: "png") else {
                        throw UltraviolenceError.resourceCreationFailure("Could not find AppleLogoMask.png in bundle")
                    }
                    maskTexture = try textureLoader.newTexture(URL: maskURL, options: [
                        .textureUsage: MTLTextureUsage.shaderRead.rawValue,
                        .textureStorageMode: MTLStorageMode.private.rawValue
                    ])
                    maskTexture?.label = "Apple Logo Mask"

                    // Load video
                    guard let videoURL = Bundle.module.url(forResource: "AppleEventVideo", withExtension: "mp4") else {
                        throw UltraviolenceError.resourceCreationFailure("Could not find AppleEventVideo.mp4 in bundle")
                    }
                    try videoPlayer.loadVideo(url: videoURL)
                    videoPlayer.play()
                }
                catch {
                    fatalError("Error: \(error)")
                }
            }

            // Debug label showing mouse position
            Text("Mouse: (\(debugMousePosition.x, format: .number.precision(.fractionLength(2))), \(debugMousePosition.y, format: .number.precision(.fractionLength(2))))")
        }
    }
}
