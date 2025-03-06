import CoreGraphics
import Metal
import MetalKit
import simd
import Ultraviolence
import UltraviolenceExampleShaders
import UltraviolenceSupport

public struct DepthShader <Content>: Element where Content: Element {
    var content: Content

    @UVState
    var vertexShader: VertexShader

    @UVState
    var fragmentShader: FragmentShader

    public init(@ElementBuilder content: () throws -> Content) throws {
        self.content = try content()
        let shaderBundle = Bundle.ultraviolenceExampleShaders().orFatalError()
        let shaderLibrary = try ShaderLibrary(bundle: shaderBundle, namespace: "DepthShader")
        self.vertexShader = try shaderLibrary.vertex_main
        self.fragmentShader = try shaderLibrary.fragment_main
    }

    public var body: some Element {
        get throws {
            try RenderPipeline(vertexShader: vertexShader, fragmentShader: fragmentShader) {
                content
            }
        }
    }
}
