import MetalKit
import SwiftUI
import Ultraviolence
import UltraviolenceSupport
import UltraviolenceUI
import UltraviolenceExampleShaders
import GeometryLite3D
import simd

public struct SDFDemoView: View {
    @State
    private var time: Float = 0

    @State
    private var projection: any ProjectionProtocol = PerspectiveProjection()

    @State
    private var cameraMatrix: simd_float4x4 = .init(translation: [0, 0, 5])

    @State
    private var drawableSize: CGSize = .zero

    @State
    private var showDepth = false

    public init() {
        // This line intentionally left blank.
    }

    public var body: some View {
        VStack {
            WorldView(projection: $projection, cameraMatrix: $cameraMatrix, targetMatrix: .constant(nil)) {
                RenderView {
                    try RenderPass {
                        try SDFRenderPipeline(
                            time: time,
                            projectionMatrix: projection.projectionMatrix(for: drawableSize),
                            cameraMatrix: cameraMatrix,
                            drawableSize: drawableSize,
                            showDepth: showDepth
                        )
                    }
                }
                .metalDepthStencilPixelFormat(.depth32Float)
                .onDrawableSizeChange { drawableSize = $0 }
                .task {
                    while !Task.isCancelled {
                        time += 0.016 // ~60 FPS
                        try? await Task.sleep(for: .milliseconds(16))
                    }
                }
            }

            Toggle("Show Depth", isOn: $showDepth)
                .padding()
        }
    }
}

struct SDFRenderPipeline: Element {
    let time: Float
    let projectionMatrix: simd_float4x4
    let cameraMatrix: simd_float4x4
    let drawableSize: CGSize
    let showDepth: Bool

    @UVState
    var vertexShader: VertexShader

    @UVState
    var fragmentShader: FragmentShader

    init(time: Float, projectionMatrix: simd_float4x4, cameraMatrix: simd_float4x4, drawableSize: CGSize, showDepth: Bool) throws {
        self.time = time
        self.projectionMatrix = projectionMatrix
        self.cameraMatrix = cameraMatrix
        self.drawableSize = drawableSize
        self.showDepth = showDepth
        let shaderBundle = Bundle.ultraviolenceExampleShaders().orFatalError()
        let shaderLibrary = try ShaderLibrary(bundle: shaderBundle, namespace: "SDFShader")
        vertexShader = try shaderLibrary.vertex_main
        fragmentShader = try shaderLibrary.fragment_main
    }

    var body: some Element {
        get throws {
            try RenderPipeline(vertexShader: vertexShader, fragmentShader: fragmentShader) {
                // Full-screen quad vertices (triangle strip order)
                let vertices: [Packed3<Float>] = [
                    [-1, -1, 0],
                    [ 1, -1, 0],
                    [-1,  1, 0],
                    [ 1,  1, 0]
                ]

                // Extract camera position from camera matrix
                let cameraPos = SIMD3<Float>(
                    cameraMatrix.columns.3.x,
                    cameraMatrix.columns.3.y,
                    cameraMatrix.columns.3.z
                )

                // Calculate view matrix (inverse of camera matrix)
                let viewMatrix = cameraMatrix.inverse

                let uniforms = UltraviolenceExampleShaders.SDFUniforms(
                    time: time,
                    resolution: SIMD2<Float>(Float(drawableSize.width), Float(drawableSize.height)),
                    cameraPos: cameraPos,
                    lightPos: SIMD3<Float>(2, 3, 1),
                    projectionMatrix: projectionMatrix,
                    viewMatrix: viewMatrix,
                    showDepth: showDepth ? 1 : 0
                )

                Draw { encoder in
                    encoder.setVertexUnsafeBytes(of: vertices, index: 0)
                    encoder.setFragmentUnsafeBytes(of: uniforms, index: 0)
                    encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: vertices.count)
                }
            }
            .vertexDescriptor(try vertexShader.inferredVertexDescriptor())
        }
    }
}