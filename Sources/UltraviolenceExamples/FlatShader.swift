import CoreGraphics
import Metal
import MetalKit
import simd
import Ultraviolence
import UltraviolenceSupport

public struct FlatShader <Content>: Element where Content: Element {
    var modelMatrix: simd_float4x4
    var cameraMatrix: simd_float4x4
    var projectionMatrix: simd_float4x4
    var content: Content
    var vertexShader: VertexShader
    var fragmentShader: FragmentShader

    var textureSpecifier: Texture2DSpecifier

    public init(modelMatrix: simd_float4x4, cameraMatrix: simd_float4x4, projectionMatrix: simd_float4x4, textureSpecifier: Texture2DSpecifier, @ElementBuilder content: () -> Content) throws {
        self.modelMatrix = modelMatrix
        self.cameraMatrix = cameraMatrix
        self.projectionMatrix = projectionMatrix
        self.textureSpecifier = textureSpecifier
        self.content = content()
        let shaderBundle = Bundle.ultraviolenceExampleShaders().orFatalError()
        let shaderLibrary = try ShaderLibrary(bundle: shaderBundle, namespace: "FlatShader")
        self.vertexShader = try shaderLibrary.vertex_main
        self.fragmentShader = try shaderLibrary.fragment_main
    }

    public var body: some Element {
        get throws {
            let textureSpecifierArgumentBuffer = textureSpecifier.toTexture2DSpecifierArgmentBuffer()

            try RenderPipeline(vertexShader: vertexShader, fragmentShader: fragmentShader) {
                content
                    .parameter("projectionMatrix", value: projectionMatrix)
                    .parameter("viewMatrix", value: cameraMatrix.inverse)
                    .parameter("modelMatrix", value: modelMatrix)
                    .parameter("texture", value: textureSpecifierArgumentBuffer)
                    .useResource(textureSpecifier.texture, usage: .read, stages: .fragment)
            }
        }
    }
}

public enum FlatShaderExample: Example {
    @MainActor
    public static func runExample() throws -> ExampleResult {
        let device = _MTLCreateSystemDefaultDevice()
        let textureLoader = MTKTextureLoader(device: device)
        let imageURL = Bundle.module.url(forResource: "HD-Testcard-original", withExtension: "jpg").orFatalError()
        let texture = try textureLoader.newTexture(URL: imageURL)
        let samplerDescriptor = MTLSamplerDescriptor(supportArgumentBuffers: true)
        let sampler = try device._makeSamplerState(descriptor: samplerDescriptor)
        return try MTLCaptureManager.shared().with(enabled: false) {
            let mesh = MTKMesh.sphere(inwardNormals: true)
            let root = try Group {
                try RenderPass {
                    let modelMatrix = simd_float4x4(scale: [100, 100, 100])
                    let cameraMatrix = simd_float4x4(translation: [0, 0, 0])
                    let projectionMatrix = PerspectiveProjection().projectionMatrix(for: .init(width: 1_024, height: 768))
                    try FlatShader(modelMatrix: modelMatrix, cameraMatrix: cameraMatrix, projectionMatrix: projectionMatrix, textureSpecifier: .texture(texture, sampler)) {
                        Draw { encoder in
                            encoder.setVertexBuffers(of: mesh)
                            encoder.draw(mesh)
                        }
                    }
                    .vertexDescriptor(MTLVertexDescriptor(mesh.vertexDescriptor))
                    .depthCompare(function: .less, enabled: true)
                }
            }
            let offscreenRenderer = try OffscreenRenderer(size: .init(width: 1_024, height: 768))
            let texture = try offscreenRenderer.render(root).texture
            return .texture(texture)
        }
    }
}
