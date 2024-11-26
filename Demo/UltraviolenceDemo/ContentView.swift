import simd
import SwiftUI
import UltraviolenceRedux

// swiftlint:disable force_try

struct ContentView: View {
    var body: some View {
        RenderView(MyRenderPass())
    }
}

#Preview {
    ContentView()
}

struct MyRenderPass: RenderPass {
    @UltraviolenceRedux.State var vertexShader: VertexShader
    @UltraviolenceRedux.State var fragmentShader: FragmentShader

    init() {
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
        vertexShader = try! VertexShader(source: source)
        fragmentShader = try! FragmentShader(source: source)
    }

    var body: some RenderPass {
        Render {
            RenderPipeline(vertexShader: vertexShader, fragmentShader: fragmentShader) {
                Draw { encoder in
                    let vertices: [SIMD2<Float>] = [[0, 0.75], [-0.75, -0.75], [0.75, -0.75]]
                    encoder.setVertexBytes(vertices, length: MemoryLayout<SIMD2<Float>>.stride * 3, index: 0)
                    encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
                }
                .parameter("color", Color.blue)
            }
        }
    }
}
