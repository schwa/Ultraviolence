import Metal
import Ultraviolence
import UltraviolenceExampleShaders
import MetalKit

struct WireframeRenderPipeline: Element {
    let vertexShader: VertexShader
    let fragmentShader: FragmentShader
    var mvpMatrix: float4x4
    var wireframeColor: SIMD4<Float>
    var mesh: MTKMesh

    init(mvpMatrix: float4x4, wireframeColor: SIMD4<Float>, mesh: MTKMesh) throws {
        let shaderBundle = Bundle.ultraviolenceExampleShaders().orFatalError()
        let shaderLibrary = try ShaderLibrary(bundle: shaderBundle, namespace: "WireframeShader")
        self.vertexShader = try shaderLibrary.vertex_main
        self.fragmentShader = try shaderLibrary.fragment_main
        self.mvpMatrix = mvpMatrix
        self.wireframeColor = wireframeColor
        self.mesh = mesh
    }

    var body: some Element {
        get throws {
            try RenderPipeline(vertexShader: vertexShader, fragmentShader: fragmentShader) {
                var uniforms = WireframeUniforms(modelViewProjectionMatrix: mvpMatrix, wireframeColor: wireframeColor)
                Draw { encoder in
                    encoder.setTriangleFillMode(.lines)
                    encoder.setVertexBuffers(of: mesh)
                    encoder.draw(mesh)
                }
                .parameter("uniforms", functionType: .vertex, value: uniforms)
                .parameter("uniforms", functionType: .fragment, value: uniforms)
            }
            .vertexDescriptor(mesh.vertexDescriptor)
        }
    }
}
