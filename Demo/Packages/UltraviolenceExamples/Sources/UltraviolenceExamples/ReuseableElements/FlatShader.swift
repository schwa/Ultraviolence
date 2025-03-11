import CoreGraphics
import Metal
import MetalKit
import simd
import Ultraviolence
import UltraviolenceExampleShaders
import UltraviolenceSupport

public struct FlatShader <Content>: Element where Content: Element {
    var content: Content

    @UVState
    var vertexShader: VertexShader

    @UVState
    var fragmentShader: FragmentShader

    var textureSpecifier: Texture2DSpecifier

    public init(textureSpecifier: Texture2DSpecifier, @ElementBuilder content: () throws -> Content) throws {
        self.textureSpecifier = textureSpecifier
        self.content = try content()
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
                    let transforms = Transforms(modelMatrix: modelMatrix, cameraMatrix: cameraMatrix, projectionMatrix: projectionMatrix)
                    try FlatShader(textureSpecifier: .texture(texture, sampler)) {
                        Draw { encoder in
                            encoder.setVertexBuffers(of: mesh)
                            encoder.draw(mesh)
                        }
                        .transforms(transforms)
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
