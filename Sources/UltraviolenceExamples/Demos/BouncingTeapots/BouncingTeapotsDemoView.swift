import MetalKit
import simd
import SwiftUI
import Ultraviolence
import UltraviolenceSupport
import UltraviolenceUI

public struct BouncingTeapotsDemoView: View {
    @State
    private var simulation = TeapotSimulation(count: 60)

    @State
    private var lastUpdate: Date?

    @State
    private var checkerboardColor: Color = .white

    @State
    private var offscreenTexture: MTLTexture?

    @State
    private var offscreenDepthTexture: MTLTexture?

    @State
    private var upscaledTexture: MTLTexture?

    @State
    private var drawableSize: CGSize = .zero

    @State
    private var scaleFactor = 1.0

    @State
    private var projection: any ProjectionProtocol = PerspectiveProjection()

    @State
    private var cameraMatrix: simd_float4x4 = .init(translation: [0, 2, 6])

    public init() {
        // This line intentionally left blank.
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
                .inspector(isPresented: .constant(false)) {
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
        WorldView(projection: $projection, cameraMatrix: $cameraMatrix, targetMatrix: .constant(nil)) {
            let transforms = Transforms(modelMatrix: .identity, cameraMatrix: cameraMatrix, projectionMatrix: projection.projectionMatrix(for: drawableSize))
            RenderView {
                if let offscreenTexture, let offscreenDepthTexture, let upscaledTexture {
                    FlyingTeapotsRenderPass(transforms: transforms, simulation: simulation, checkerboardColor: checkerboardColor, offscreenTexture: offscreenTexture, offscreenDepthTexture: offscreenDepthTexture, upscaledTexture: upscaledTexture)
                }
            }
            .metalDepthStencilPixelFormat(.depth32Float)
            .onDrawableSizeChange { size in
                drawableSize = size
            }
            .onChange(of: drawableSize) {
                regenerateTextures()
            }
            .onChange(of: scaleFactor) {
                regenerateTextures()
            }
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
    @UVState
    var mesh: MTKMesh = .teapot()
    @UVState
    var sphere: MTKMesh = .sphere(extent: [100, 100, 100], inwardNormals: true)
    @UVState
    var skyboxSampler: MTLSamplerState
    @UVState
    var skyboxTexture: MTLTexture

    var transforms: Transforms

    let simulation: TeapotSimulation
    let checkerboardColor: Color
    let offscreenTexture: MTLTexture
    let offscreenDepthTexture: MTLTexture
    let upscaledTexture: MTLTexture

    init(transforms: Transforms, simulation: TeapotSimulation, checkerboardColor: Color, offscreenTexture: MTLTexture, offscreenDepthTexture: MTLTexture, upscaledTexture: MTLTexture) {
        let device = _MTLCreateSystemDefaultDevice()
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: 2_048, height: 2_048, mipmapped: false)
        textureDescriptor.usage = [.shaderRead, .shaderWrite]
        skyboxTexture = device.makeTexture(descriptor: textureDescriptor).orFatalError()
        let samplerDescriptor = MTLSamplerDescriptor(supportArgumentBuffers: true)
        skyboxSampler = device.makeSamplerState(descriptor: samplerDescriptor).orFatalError()
        self.checkerboardColor = checkerboardColor
        self.simulation = simulation
        self.offscreenTexture = offscreenTexture
        self.offscreenDepthTexture = offscreenDepthTexture
        self.upscaledTexture = upscaledTexture
        self.transforms = transforms
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
                try FlatShader(textureSpecifier: .texture(skyboxTexture, skyboxSampler)) {
                    Draw { encoder in
                        encoder.setVertexBuffers(of: sphere)
                        encoder.draw(sphere)
                    }
                    .transforms(transforms)
                }
                .vertexDescriptor(MTLVertexDescriptor(sphere.vertexDescriptor))

                // Teapot party.
                try LambertianShaderInstanced(transforms: transforms, colors: colors, modelMatrices: modelMatrices, lightDirection: [-1, -2, -1]) {
                    Draw { encoder in
                        encoder.setVertexBuffers(of: mesh)
                        encoder.draw(mesh, instanceCount: simulation.teapots.count)
                    }
                }
                .vertexDescriptor(MTLVertexDescriptor(mesh.vertexDescriptor))
            }
            .depthCompare(function: .less, enabled: true)
            #if canImport(MetalFX)
            .renderPassDescriptorModifier { descriptor in
                descriptor.colorAttachments[0].texture = offscreenTexture
                descriptor.depthAttachment.texture = offscreenDepthTexture
            }
            #endif

            #if canImport(MetalFX)
            MetalFXSpatial(inputTexture: offscreenTexture, outputTexture: upscaledTexture)
            try RenderPass {
                try BillboardRenderPipeline(texture: upscaledTexture)
            }
            .depthCompare(function: .always, enabled: false)
            #endif
        }
    }
}

extension BouncingTeapotsDemoView: DemoView {
    public static var metadata: DemoMetadata {
        DemoMetadata(
            name: "Bouncing Teapots",
            description: "Physics simulation of animated teapots with MetalFX upscaling and instanced rendering",
            keywords: ["instancing", "metalfx"],
            color: .yellow
        )
    }
}
