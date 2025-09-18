import Metal
import simd
import Ultraviolence
import UltraviolenceExampleShaders

public struct AxisLinesRenderPipeline: Element {
    let vertexShader: VertexShader
    let fragmentShader: FragmentShader
    let mvpMatrix: float4x4
    let scale: Float
    let nudge: SIMD3<Float>

    public init(mvpMatrix: float4x4, scale: Float = 1.0, nudge: SIMD3<Float> = .zero) throws {
        let library = try ShaderLibrary(bundle: .ultraviolenceExampleShaders(), namespace: "AxisLines")
        vertexShader = try library.vertex_main
        fragmentShader = try library.fragment_main
        self.mvpMatrix = mvpMatrix
        self.scale = scale
        self.nudge = nudge
    }

    public var body: some Element {
        get throws {
            try RenderPipeline(vertexShader: vertexShader, fragmentShader: fragmentShader) {
                Draw { encoder in
                    let uniforms = AxisLinesUniforms(mvpMatrix: mvpMatrix, scale: scale, nudge: nudge)
                    encoder.setVertexBytes([uniforms], length: MemoryLayout<AxisLinesUniforms>.size, index: 0)
                    encoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: 6)
                }
            }
            .vertexDescriptor(try vertexShader.inferredVertexDescriptor())
        }
    }
}
