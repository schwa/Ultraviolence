import Metal
import simd
import Ultraviolence
import UltraviolenceExampleShaders

public struct AxisAlignedWireframeBoxesRenderPipeline: Element {

    let vertexShader: VertexShader
    let fragmentShader: FragmentShader
    let mvpMatrix: float4x4
    let boxes: [BoxInstance]
    let nudge: SIMD3<Float>

    public init(mvpMatrix: float4x4, boxes: [BoxInstance], nudge: SIMD3<Float> = .zero) throws {
        let library = try ShaderLibrary(bundle: .ultraviolenceExampleShaders(), namespace: "Boxes")
        vertexShader = try library.vertex_main
        fragmentShader = try library.fragment_main
        self.mvpMatrix = mvpMatrix
        self.boxes = boxes
        self.nudge = nudge
    }

    public var body: some Element {
        get throws {
            try RenderPipeline(vertexShader: vertexShader, fragmentShader: fragmentShader) {
                Draw { encoder in
                    let uniforms = BoxesUniforms(mvpMatrix: mvpMatrix, nudge: nudge)
                    encoder.setVertexBytes([uniforms], length: MemoryLayout<BoxesUniforms>.size, index: 0)
                    encoder.setVertexBytes(boxes, length: MemoryLayout<BoxInstance>.stride * boxes.count, index: 1)
                    encoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount: 24, instanceCount: boxes.count)
                }
            }
            .vertexDescriptor(try vertexShader.inferredVertexDescriptor())
        }
    }
}