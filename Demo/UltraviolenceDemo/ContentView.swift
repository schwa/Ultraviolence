import SwiftUI
import Ultraviolence
import MetalKit
import Metal

struct MyRenderPass: RenderPass {
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

    var body: some RenderPass {
        try! Draw([Quad2D(origin: [-0.5, -0.5], size: [1, 1])]) {
            try VertexShader("vertex_main", source: source)
            try FragmentShader("fragment_main", source: source)
        }
    }
}

struct ContentView: View {
    var body: some View {
        RenderView(MyRenderPass())
    }
}

#Preview {
    ContentView()
}
