import MetalKit
import simd
import SwiftUI
import Ultraviolence
import UltraviolenceExamples
import UltraviolenceSupport

struct TriangleDemoView: View {
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

    @State
    private var color: SIMD4<Float> = [1, 0, 0, 1]

    var body: some View {
        TimelineView(.animation()) { timeline in
            RenderView {
                try RenderPass {
                    let vertexShader = try VertexShader(source: source)
                    let fragmentShader = try FragmentShader(source: source)
                    RenderPipeline(vertexShader: vertexShader, fragmentShader: fragmentShader) {
                        Draw { encoder in
                            let vertices: [SIMD2<Float>] = [[0, 0.75], [-0.75, -0.75], [0.75, -0.75]]
                            encoder.setVertexBytes(vertices, length: MemoryLayout<SIMD2<Float>>.stride * 3, index: 0)
                            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
                        }
                        .parameter("color", color)
                    }
                }
            }
            .metalDepthStencilPixelFormat(.depth32Float)
            .onChange(of: timeline.date) { _, new in
                let timeInterval = new.timeIntervalSince1970
                let red = (1 + sin(timeInterval * 2 * .pi / 0.3)) / 2
                let green = (1 + sin(timeInterval * 2 * .pi / 0.5)) / 2
                let blue = (1 + sin(timeInterval * 2 * .pi / 0.7)) / 2
                color = [Float(red), Float(green), Float(blue), 1]
            }
        }
    }
}

extension TriangleDemoView: DemoView {
}
