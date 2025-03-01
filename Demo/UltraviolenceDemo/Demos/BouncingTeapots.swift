import MetalKit
import simd
import SwiftUI
import Ultraviolence
import UltraviolenceExamples
import UltraviolenceSupport

public struct BouncingTeapotsDemoView: View {
    @State
    private var simulation = TeapotSimulation(count: 60)

    @State
    private var lastUpdate: Date?

    @State
    private var checkerboardColor: Color = .white

    @State
    var offscreenTexture: MTLTexture?

    @State
    var offscreenDepthTexture: MTLTexture?

    @State
    var upscaledTexture: MTLTexture?

    @State
    var drawableSize: CGSize = .zero

    @State
    var scaleFactor = 1.0

    public init() {
    }

    public var body: some View {
        TimelineView(.animation) { timeline in
            renderView()
                .onChange(of: timeline.date) {
                    let now = timeline.date
                    if let lastUpdate {
                        simulation.step(duration: now.timeIntervalSince(lastUpdate))
                    }
                    lastUpdate = now
                }
                .inspector(isPresented: .constant(true)) {
                    Form {
                        ColorPicker("Checkerboard Color", selection: $checkerboardColor)
                        LabeledContent("MetalFX") {
                            Text("Upsampled Size: \(drawableSize.width, format: .number) x \(drawableSize.height, format: .number)")
                            Text("Render Size: \(scaleFactor * drawableSize.width, format: .number) x \(scaleFactor * drawableSize.height, format: .number)")
                            Text("Scale Factor: \(scaleFactor)")
                            Slider(value: $scaleFactor, in: 0.0125...1.0)
                        }
                    }
                }
        }
    }

    @ViewBuilder
    func renderView() -> some View {
        RenderView {
            if let offscreenTexture, let offscreenDepthTexture, let upscaledTexture {
                FlyingTeapotsRenderPass(simulation: simulation, checkerboardColor: checkerboardColor, offscreenTexture: offscreenTexture, offscreenDepthTexture: offscreenDepthTexture, upscaledTexture: upscaledTexture)
            }
        }
        .metalDepthStencilPixelFormat(.depth32Float)
        .onDrawableSizeChange { size in
            self.drawableSize = size
        }
        .onChange(of: drawableSize) {
            regenerateTextures()
        }
        .onChange(of: scaleFactor) {
            regenerateTextures()
        }
    }

    func regenerateTextures() {
        let offscreenDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: Int(scaleFactor * drawableSize.width), height: Int(scaleFactor * drawableSize.height), mipmapped: false)
        offscreenDescriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
        let offscreenTexture = _MTLCreateSystemDefaultDevice().makeTexture(descriptor: offscreenDescriptor).orFatalError()
        offscreenTexture.label = "Offscreen Texture"
        self.offscreenTexture = offscreenTexture

        let offscreenDepthTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float, width: Int(scaleFactor * drawableSize.width), height: Int(scaleFactor * drawableSize.height), mipmapped: false)
        offscreenDepthTextureDescriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
        offscreenDepthTextureDescriptor.storageMode = .private
        let offscreenDepthTexture = _MTLCreateSystemDefaultDevice().makeTexture(descriptor: offscreenDepthTextureDescriptor).orFatalError()
        offscreenDepthTexture.label = "Offscreen Depth Texture"
        self.offscreenDepthTexture = offscreenDepthTexture

        let upscaledDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: Int(drawableSize.width), height: Int(drawableSize.height), mipmapped: false)
        upscaledDescriptor.usage = [.shaderRead, .shaderWrite, .renderTarget]
        upscaledDescriptor.storageMode = .private
        let upscaledTexture = _MTLCreateSystemDefaultDevice().makeTexture(descriptor: upscaledDescriptor).orFatalError()
        upscaledTexture.label = "Upscaled Texture"
        self.upscaledTexture = upscaledTexture
    }
}

// MARK: -

struct FlyingTeapotsRenderPass: Element {

    @UVEnvironment(\.device)
    var device

    @UVEnvironment(\.drawableSize)
    var drawableSize

    @UVState
    var mesh: MTKMesh = .teapot()
    @UVState
    var sphere: MTKMesh = .sphere(extent: [100, 100, 100], inwardNormals: true)
    @UVState
    var skyboxSampler: MTLSamplerState
    @UVState
    var skyboxTexture: MTLTexture

    let cameraMatrix: simd_float4x4 = .init(translation: [0, 2, 6])
    var projectionMatrix: simd_float4x4 {
        PerspectiveProjection().projectionMatrix(for: drawableSize.orFatalError())
    }

    let simulation: TeapotSimulation
    let checkerboardColor: Color
    let offscreenTexture: MTLTexture
    let offscreenDepthTexture: MTLTexture
    let upscaledTexture: MTLTexture

    public init(simulation: TeapotSimulation, checkerboardColor: Color, offscreenTexture: MTLTexture, offscreenDepthTexture: MTLTexture, upscaledTexture: MTLTexture) {
        let device = _MTLCreateSystemDefaultDevice()
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: 2_048, height: 2_048, mipmapped: false)
        textureDescriptor.usage = [.shaderRead, .shaderWrite]
        skyboxTexture = device.makeTexture(descriptor: textureDescriptor).orFatalError()
        let samplerDescriptor = MTLSamplerDescriptor()
        skyboxSampler = device.makeSamplerState(descriptor: samplerDescriptor).orFatalError()
        self.checkerboardColor = checkerboardColor
        self.simulation = simulation
        self.offscreenTexture = offscreenTexture
        self.offscreenDepthTexture = offscreenDepthTexture
        self.upscaledTexture = upscaledTexture
    }

    var body: some Element {
        get throws {
            let colors = simulation.teapots.map(\.color)
            let modelMatrices = simulation.teapots.map(\.matrix)

            try ComputePass {
                // Render a checkerboard pattern into a texture
                try CheckerboardKernel(outputTexture: skyboxTexture, checkerSize: [20, 20], foregroundColor: [1, 1, 1, 1])
                // And some circles
                try CircleGridKernel(outputTexture: skyboxTexture, spacing: [128, 128], radius: 32, foregroundColor: .init(color: checkerboardColor))
            }
            try RenderPass {
                // Draw the checkerboard texture into a skybox
                try FlatShader(modelMatrix: .identity, cameraMatrix: cameraMatrix, projectionMatrix: projectionMatrix, texture: skyboxTexture, sampler: skyboxSampler) {
                    Draw { encoder in
                        encoder.setVertexBuffers(of: sphere)
                        encoder.draw(sphere)
                    }
                }
                .vertexDescriptor(MTLVertexDescriptor(sphere.vertexDescriptor))

                // Teapot party.
                try LambertianShaderInstanced(colors: colors, modelMatrices: modelMatrices, cameraMatrix: cameraMatrix, projectionMatrix: projectionMatrix, lightDirection: [-1, -2, -1]) {
                    Draw { encoder in
                        encoder.setVertexBuffers(of: mesh)
                        encoder.draw(mesh, instanceCount: simulation.teapots.count)
                    }
                }
                .vertexDescriptor(MTLVertexDescriptor(mesh.vertexDescriptor))
            }
            .depthCompare(function: .less, enabled: true)
            #if os(macOS)
            .renderPassDescriptorModifier { descriptor in
                descriptor.colorAttachments[0].texture = offscreenTexture
                descriptor.depthAttachment.texture = offscreenDepthTexture
            }
            #endif

            #if os(macOS)
            MetalFXSpatial(inputTexture: offscreenTexture, outputTexture: upscaledTexture)
            try RenderPass {
                try BillboardRenderPipeline(texture: upscaledTexture)
            }
            .depthCompare(function: .always, enabled: false)
            #endif
        }
    }
}

// MARK: -

internal struct Teapot {
    var position: SIMD3<Float>
    var rotation: simd_quatf
    var rotationVelocity: simd_quatf
    var velocity: SIMD3<Float>
    var color: SIMD3<Float>
}

internal struct TeapotSimulation {
    var teapots: [Teapot] = []
    var boundingBox: BoundingBox = .init(min: [-4, 0, -4], max: [4, 4, 4])

    init(count: Int) {
        // create random teapots
        teapots = (0..<count).map { _ in
            Teapot(
                position: [Float.random(in: -1...1), Float.random(in: -1...1), Float.random(in: -1...1)],
                rotation: simd_quatf(angle: .init(Float.random(in: 0...(2 * .pi))), axis: [Float.random(in: -1...1), Float.random(in: -1...1), Float.random(in: -1...1)]),
                rotationVelocity: simd_quatf(angle: .init(Float.random(in: -1...1)), axis: [Float.random(in: -1...1), Float.random(in: -1...1), Float.random(in: -1...1)]),
                velocity: [Float.random(in: -1...1), Float.random(in: -1...1), Float.random(in: -1...1)] * 5,
                color: [Float.random(in: 0...1), Float.random(in: 0...1), Float.random(in: 0...1)]
            )
        }
    }

    mutating func step(duration: TimeInterval) {
        teapots = teapots.map { teapot in
            var teapot = teapot
            teapot.position += teapot.velocity * Float(duration)
            if teapot.position.x < boundingBox.min.x {
                teapot.position.x = boundingBox.min.x
                teapot.velocity.x = -teapot.velocity.x
            }
            if teapot.position.x > boundingBox.max.x {
                teapot.position.x = boundingBox.max.x
                teapot.velocity.x = -teapot.velocity.x
            }
            if teapot.position.y < boundingBox.min.y {
                teapot.position.y = boundingBox.min.y
                teapot.velocity.y = -teapot.velocity.y
            }
            if teapot.position.y > boundingBox.max.y {
                teapot.position.y = boundingBox.max.y
                teapot.velocity.y = -teapot.velocity.y
            }
            if teapot.position.z < boundingBox.min.z {
                teapot.position.z = boundingBox.min.z
                teapot.velocity.z = -teapot.velocity.z
            }
            if teapot.position.z > boundingBox.max.z {
                teapot.position.z = boundingBox.max.z
                teapot.velocity.z = -teapot.velocity.z
            }
            teapot.rotation = simd_slerp(teapot.rotation, teapot.rotation * teapot.rotationVelocity, Float(duration))
            return teapot
        }
    }
}

internal struct BoundingBox {
    var min: SIMD3<Float>
    var max: SIMD3<Float>
}

extension Teapot {
    var matrix: simd_float4x4 {
        var matrix = simd_float4x4.identity
        matrix *= simd_float4x4(translation: position) // Apply translation last
        matrix *= simd_float4x4(rotation)             // Apply rotation second
        matrix *= simd_float4x4(scale: [0.2, 0.2, 0.2]) // Apply scaling first
        return matrix
    }
}

extension SIMD4<Float> {
    init(color: Color) {
        let resolved = color.resolve(in: .init())
        self = [
            Float(resolved.linearRed),
            Float(resolved.linearGreen),
            Float(resolved.linearBlue),
            Float(1.0) // TODO:
        ]
    }
}

extension BouncingTeapotsDemoView: DemoView {
}
