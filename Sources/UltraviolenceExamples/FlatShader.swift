import CoreGraphics
import Metal
import MetalKit
import simd
import Ultraviolence
internal import UltraviolenceSupport

public struct FlatShader <Content>: Element where Content: Element {
    var modelMatrix: simd_float4x4
    var cameraMatrix: simd_float4x4
    var projectionMatrix: simd_float4x4
    var content: Content
    var vertexShader: VertexShader
    var fragmentShader: FragmentShader
    var texture: MTLTexture
    var sampler: MTLSamplerState

    public init(modelMatrix: simd_float4x4, cameraMatrix: simd_float4x4, projectionMatrix: simd_float4x4, texture: MTLTexture, sampler: MTLSamplerState, @ElementBuilder content: () -> Content) throws {
        self.modelMatrix = modelMatrix
        self.cameraMatrix = cameraMatrix
        self.projectionMatrix = projectionMatrix
        self.texture = texture
        self.sampler = sampler
        self.content = content()
        let library = try ShaderLibrary(bundle: .module, namespace: "FlatShader")
        self.vertexShader = try library.vertex_main
        self.fragmentShader = try library.fragment_main
    }

    public var body: some Element {
        RenderPipeline(vertexShader: vertexShader, fragmentShader: fragmentShader) {
            content
                .parameter("projectionMatrix", value: projectionMatrix)
                .parameter("viewMatrix", value: cameraMatrix.inverse)
                .parameter("modelMatrix", value: modelMatrix)
                .parameter("texture", texture: texture)
                .parameter("sampler", samplerState: sampler)
        }
    }
}

public enum FlatShaderExample: Example {
    @MainActor
    public static func runExample() throws -> MTLTexture {
        let device = try MTLCreateSystemDefaultDevice().orThrow(.resourceCreationFailure)
        let textureLoader = MTKTextureLoader(device: device)
        let texture = try textureLoader.newTexture(name: "HD-Testcard-original", scaleFactor: 1, bundle: Bundle.module)

        let samplerDescriptor = MTLSamplerDescriptor()
        let sampler = device.makeSamplerState(descriptor: samplerDescriptor)!

        return try MTLCaptureManager.shared().with(enabled: false) {
            let mesh = MTKMesh.unitSphere(inwardNormals: true)
            let renderPass = try RenderPass {
                let modelMatrix = simd_float4x4(scale: [100, 100, 100])
                let cameraMatrix = simd_float4x4(translation: [0, 0, 0])
                let projectionMatrix = PerspectiveProjection().projectionMatrix(for: .init(width: 1_024, height: 768))
                try FlatShader(modelMatrix: modelMatrix, cameraMatrix: cameraMatrix, projectionMatrix: projectionMatrix, texture: texture, sampler: sampler) {
                    Draw { encoder in
                        encoder.setVertexBuffers(of: mesh)
                        encoder.draw(mesh)
                    }
                }
                .vertexDescriptor(MTLVertexDescriptor(mesh.vertexDescriptor))
                .depthCompare(function: .less, enabled: true)
            }
            let offscreenRenderer = try OffscreenRenderer(size: .init(width: 1_024, height: 768))
            return try offscreenRenderer.render(renderPass).texture
        }
    }
}
