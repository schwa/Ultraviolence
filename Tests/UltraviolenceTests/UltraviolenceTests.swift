import Testing
import CoreGraphics
@testable import Ultraviolence

struct RenderingTests {

    @Test
    func simpleRender() async throws {
        let source = """
        #include <metal_stdlib>

        using namespace metal;

        struct VertexIn {
            float4 position [[attribute(0)]];
        };

        struct VertexOut {
            float4 position [[position]];
        };

        [[vertex]] VertexOut vertex_main(const VertexIn in [[stage_in]]) {
            return VertexOut { in.position };
        }

        [[fragment]] float4 fragment_main() {
            return float4(1.0, 0.0, 0.0, 1.0);
        }
    """

        let renderer = try Renderer {
            try Draw([Quad2D(origin: [-0.5, -0.5], size: [1, 1])]) {
                try VertexShader("vertex_main", source: source)
                try FragmentShader("fragment_main", source: source)
            }
        }
        let image = try renderer.render(size: CGSize(width: 1600, height: 1200)).cgImage
        #expect(image !== nil)
    }

}
