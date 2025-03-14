import MetalKit
import simd
import SwiftUI
import Ultraviolence
import UltraviolenceSupport
import UltraviolenceUI

public struct TriangleDemoView: View {
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

    @State
    private var gpuTime: Double = 0

    @State
    private var kernelTime: Double = 0

    public init() {
    }

    public var body: some View {
        TimelineView(.animation()) { timeline in
            RenderView {
                try RenderPass {
                    let vertexShader = try VertexShader(source: source)
                    let fragmentShader = try FragmentShader(source: source)
                    try RenderPipeline(vertexShader: vertexShader, fragmentShader: fragmentShader) {
                        Draw { encoder in
                            let vertices: [SIMD2<Float>] = [[0, 0.75], [-0.75, -0.75], [0.75, -0.75]]
                            encoder.setVertexBytes(vertices, length: MemoryLayout<SIMD2<Float>>.stride * 3, index: 0)
                            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
                        }
                        .parameter("color", color)
                    }
                }
                .onCommandBufferScheduled { _ in
                    print("**** onCommandBufferScheduled")
                }
                .onCommandBufferCompleted { commandBuffer in
                    gpuTime = commandBuffer.gpuEndTime - commandBuffer.gpuStartTime
                    kernelTime = commandBuffer.kernelEndTime - commandBuffer.kernelStartTime
                }
            }
            .overlay(alignment: .topLeading) {
                Form {
                    let gpuTime = Measurement(value: gpuTime, unit: UnitDuration.seconds).converted(to: .milliseconds)
                    let kernelTime = Measurement(value: kernelTime, unit: UnitDuration.seconds).converted(to: .milliseconds)
                    LabeledContent("GPU Time", value: gpuTime.formatted())
                    LabeledContent("Kernel Time", value: kernelTime.formatted())
                }
                .monospacedDigit()
                .frame(width: 300)
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                .padding()
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
