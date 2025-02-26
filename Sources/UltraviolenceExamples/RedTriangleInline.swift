import AppKit
import CoreGraphics
import ImageIO
import Metal
internal import os
import simd
import Ultraviolence
import UniformTypeIdentifiers

public enum RedTriangleInline {
    @MainActor
    static func main() throws -> MTLTexture {
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

        let root = try RenderPass {
            RenderPipeline(vertexShader: vertexShader, fragmentShader: fragmentShader) {
                Draw { encoder in
                    let vertices: [SIMD2<Float>] = [[0, 0.75], [-0.75, -0.75], [0.75, -0.75]]
                    encoder.setVertexBytes(vertices, length: MemoryLayout<SIMD2<Float>>.stride * 3, index: 0)
                    encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
                }
                .parameter("color", SIMD4<Float>([1, 0, 0, 1]))
            }
        }

        let offscreenRenderer = try OffscreenRenderer(size: CGSize(width: 1_600, height: 1_200))
        return try offscreenRenderer.render(root).texture
    }
}

extension RedTriangleInline: Example {
    public static func runExample() throws -> ExampleResult {
        .texture(try RedTriangleInline.main())
    }
}
