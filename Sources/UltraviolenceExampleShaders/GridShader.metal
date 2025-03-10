#import <metal_stdlib>
#import "include/UltraviolenceExampleShaders.h"

using namespace metal;

namespace GridShader {

    // Vertex Input
    struct VertexInput {
        float3 position [[attribute(0)]];
        float2 uv [[attribute(1)]];
    };

    // Vertex Output
    struct VertexOutput {
        float4 position [[position]];
        float2 uv;
    };

    // Vertex Shader
    vertex VertexOutput vertex_main(
        VertexInput in [[stage_in]],
        constant Transforms &transforms [[buffer(2)]]
    ) {
        VertexOutput out;
        out.position = transforms.modelViewProjectionMatrix * float4(in.position, 1.0);
        out.uv = in.uv;
        return out;
    }

    // Fragment Shader - Simple Anti-Aliased Grid
    fragment float4 fragment_main(
        VertexOutput in [[stage_in]],
        constant float2 &gridScale [[buffer(1)]],
        constant float4 &gridColor [[buffer(3)]],
        constant float4 &backgroundColor [[buffer(4)]]
    ) {
        float2 gridUV = in.uv * 1.0 / gridScale;

        float2 gridLines = abs(fract(gridUV) - 0.5) / fwidth(gridUV);
        float grid = min(gridLines.x, gridLines.y); // Take the smaller of the two axes
        grid = 1.0 - smoothstep(0.5, 0.6, grid); // Smooth the transition

        // Return the final color

        return mix(backgroundColor, gridColor, grid);

    }
}
