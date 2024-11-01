import SwiftUI
import Ultraviolence

struct MyRenderPass: RenderPass {
    let source = """
        #include <metal_stdlib>

        using namespace metal;

        struct VertexIn {
            float3 position [[attribute(0)]];
        };

        struct VertexOut {
            float4 position [[position]];
        };

        [[vertex]] VertexOut vertex_main(const VertexIn in [[stage_in]]) {
            return VertexOut { float4(in.position, 1.0) };
        }

        [[fragment]] float4 fragment_main(
            constant float4 &color [[buffer(1)]]
        ) {
            return color;
        }
    """

    let color: SIMD4<Float>

    var body: some RenderPass {
        return try! Draw([Quad2D(origin: [-0.5, -0.5], size: [1, 1])]) {
            try VertexShader("vertex_main", source: source)
            try FragmentShader("fragment_main", source: source)
        }
        .argument(type: .fragment, name: "color", value: color)
    }
}

struct ContentView: View {

    @SwiftUI.State
    var color: SIMD4<Float> = [0, 0, 0, 1]

    var body: some View {
        RenderView(MyRenderPass(color: color))
        .overlay(alignment: .topTrailing) {
            SIMDColorPicker(value: $color)
            .padding()
            .background(.thinMaterial)
            .cornerRadius(8)
            .padding()
        }
    }
}

#Preview {
    ContentView()
}

