import Combine
import MetalKit
import simd
import SwiftUI
import Testing
@testable import Ultraviolence
import UltraviolenceSupport
import UltraviolenceUI

@Test
@MainActor
func testRendering() throws {
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

    let color: SIMD4<Float> = [1, 0, 0, 1]
    var gpuTime: Double = 0
    var kernelTime: Double = 0
    var gotScheduled = false
    var gotCompleted = false

    let renderPass = try RenderPass {
        let vertexShader = try VertexShader(source: source)
        let fragmentShader = try FragmentShader(source: source)
        try RenderPipeline(vertexShader: vertexShader, fragmentShader: fragmentShader) {
            Draw { encoder in
                let vertices: [SIMD2<Float>] = [[0, 0.75], [-0.75, -0.75], [0.75, -0.75]]
                encoder.setVertexBytes(vertices, length: MemoryLayout<SIMD2<Float>>.stride * 3, index: 0)
                encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            }
            .parameter("color", value: color)
        }
    }

    // TODO: #150 OffscreenRenderer creates own command buffer without giving us a chance to intercept
    .onCommandBufferScheduled { _ in
        print("**** onCommandBufferScheduled")
        gotScheduled = true
    }
    .onCommandBufferCompleted { commandBuffer in
        gpuTime = commandBuffer.gpuEndTime - commandBuffer.gpuStartTime
        kernelTime = commandBuffer.kernelEndTime - commandBuffer.kernelStartTime
        gotCompleted = true
    }

    let offscreenRenderer = try OffscreenRenderer(size: CGSize(width: 1_600, height: 1_200))
    let image = try offscreenRenderer.render(renderPass).cgImage
    #expect(try image.isEqualToGoldenImage(named: "RedTriangle"))

    // See above TODO.
    #expect(gotScheduled == true)
    #expect(gotCompleted == true)
    #expect(gpuTime > 0)
    #expect(kernelTime > 0)
}
