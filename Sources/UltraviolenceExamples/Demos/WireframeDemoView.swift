import GeometryLite3D
import Metal
import MetalKit
import simd
import SwiftUI
import Ultraviolence
import UltraviolenceSupport
import UltraviolenceUI
import UltraviolenceExampleShaders

public struct WireframeDemoView: View {
    @State
    private var wireframeColor: SIMD4<Float> = [0, 1, 0, 1]

    @State
    private var rotationAngle: Float = 0

    @State
    private var projection: any ProjectionProtocol = PerspectiveProjection()

    @State
    private var cameraMatrix: simd_float4x4 = .init(translation: [0, 2, 6])

    let teapotMesh = MTKMesh.teapot().relabeled("wireframe-teapot")

    public init() {
    }

    public var body: some View {
        WorldView(projection: $projection, cameraMatrix: $cameraMatrix, targetMatrix: .constant(nil)) {
            RenderView { _, drawableSize in
                let projectionMatrix = projection.projectionMatrix(for: drawableSize)
                let viewMatrix = cameraMatrix.inverse
                let modelMatrix = float4x4.identity
                let mvpMatrix = projectionMatrix * viewMatrix * modelMatrix

                try RenderPass {
                    GridShader(projectionMatrix: projectionMatrix, cameraMatrix: cameraMatrix)
                    try AxisLinesRenderPipeline(mvpMatrix: projectionMatrix * viewMatrix, scale: 10_000.0)
                    try WireframeRenderPipeline(mvpMatrix: mvpMatrix, wireframeColor: wireframeColor, mesh: teapotMesh)
                }
            }
            .metalDepthStencilPixelFormat(.depth32Float)
        }
    }
}

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
