import CoreGraphics
import ImageIO
import Metal
import simd
import Ultraviolence
import UniformTypeIdentifiers

public struct RedTriangle: Element {
    public init() {
        // This line intentionally left blank.
    }

    public var body: some Element {
        get throws {
            let library = try ShaderLibrary(bundle: .module, namespace: "RedTriangle")
            let vertexShader: VertexShader = try library.vertex_main
            let fragmentShader: FragmentShader = try library.fragment_main

            try RenderPass {
                try RenderPipeline(vertexShader: vertexShader, fragmentShader: fragmentShader) {
                    Draw { encoder in
                        let vertices: [SIMD2<Float>] = [[0, 0.75], [-0.75, -0.75], [0.75, -0.75]]
                        encoder.setVertexBytes(vertices, length: MemoryLayout<SIMD2<Float>>.stride * 3, index: 0)
                        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
                    }
                    .parameter("color", SIMD4<Float>([1, 0, 0, 1]))
                }
            }
        }
    }
}
