import Foundation
import simd
import Testing
@testable import Ultraviolence

@Test
@MainActor
func testVideoRenderer() async throws {
    let outputURL = URL(fileURLWithPath: "/tmp/RedTriangleVideo.mov")

    let renderer = try OffscreenVideoRenderer(
        size: CGSize(width: 640, height: 480),
        frameRate: 30.0,
        outputURL: outputURL
    )

    let source = """
    #include <metal_stdlib>
    using namespace metal;

    struct VertexIn {
        float2 position [[attribute(0)]];
    };

    struct VertexOut {
        float4 position [[position]];
    };

    [[vertex]] VertexOut vertex_main(
        const VertexIn in [[stage_in]]
    ) {
        VertexOut out;
        out.position = float4(in.position, 0.0, 1.0);
        return out;
    }

    [[fragment]] float4 fragment_main(
        VertexOut in [[stage_in]],
        constant float4 &color [[buffer(0)]]
    ) {
        return color;
    }
    """
    let vertexShader = try VertexShader(source: source)
    let fragmentShader = try FragmentShader(source: source)

    for frame in 0..<30 {
        let color: SIMD4<Float> = [Float(frame) / 30, 0, 0, 1]
        let triangle = try RenderPass {
            try RenderPipeline(vertexShader: vertexShader, fragmentShader: fragmentShader) {
                Draw { encoder in
                    let vertices: [SIMD2<Float>] = [[0, 0.75], [-0.75, -0.75], [0.75, -0.75]]
                    encoder.setVertexBytes(vertices, length: MemoryLayout<SIMD2<Float>>.stride * 3, index: 0)
                    encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
                }
                .parameter("color", value: color)
            }
            .vertexDescriptor(try vertexShader.inferredVertexDescriptor())
        }
        try renderer.render(triangle)
    }
    try await renderer.finalize()
    #expect(FileManager.default.fileExists(atPath: outputURL.path))
}
