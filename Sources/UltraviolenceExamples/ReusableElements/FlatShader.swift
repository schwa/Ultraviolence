import CoreGraphics
import GeometryLite3D
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

    var textureSpecifier: ColorSource

    // TODO: Remove texture specifier and use a parameter/element extension [FILE ME]
    public init(textureSpecifier: ColorSource, @ElementBuilder content: () throws -> Content) throws {
        self.textureSpecifier = textureSpecifier
        self.content = try content()
        let shaderBundle = Bundle.ultraviolenceExampleShaders().orFatalError()
        let shaderLibrary = try ShaderLibrary(bundle: shaderBundle, namespace: "FlatShader")
        self.vertexShader = try shaderLibrary.vertex_main
        self.fragmentShader = try shaderLibrary.fragment_main
    }

    public var body: some Element {
        get throws {
            let textureSpecifierArgumentBuffer = textureSpecifier.toArgumentBuffer()

            try RenderPipeline(vertexShader: vertexShader, fragmentShader: fragmentShader) {
                content
                    .parameter("specifier", value: textureSpecifierArgumentBuffer)
                    .useResource(textureSpecifier.texture2D, usage: .read, stages: .fragment)
                    .useResource(textureSpecifier.textureCube, usage: .read, stages: .fragment)
                    .useResource(textureSpecifier.depth2D, usage: .read, stages: .fragment)
            }
        }
    }
}
