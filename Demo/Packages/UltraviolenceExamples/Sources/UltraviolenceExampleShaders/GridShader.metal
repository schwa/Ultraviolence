#import "include/UltraviolenceExampleShaders.h"
#import <metal_stdlib>

using namespace metal;

namespace GridShader {
    float pristineGrid(float2 uv, float2 lineWidth);

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
    vertex VertexOutput vertex_main(VertexInput in [[stage_in]], constant Transforms &transforms [[buffer(2)]]) {
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
        grid = 1.0 - smoothstep(0.5, 0.6, grid);    // Smooth the transition
        return mix(backgroundColor, gridColor, grid);

        //                                      float2 gridLineWidth =
        //                                      float2(0.005, 0.995); // Line
        //                                      width control float gridVal =
        //                                      pristineGrid(in.uv,
        //                                      gridLineWidth); return
        //                                      float4(gridVal, gridVal,
        //                                      gridVal, 1.0); // Grayscale grid
        //                                      output
    }

    float pristineGrid(float2 uv, float2 lineWidth) {
        lineWidth = saturate(lineWidth);

        const float4 uvDerivatives = float4(dfdx(uv), dfdy(uv));
        const float2 uvLengthDerivatives = float2(length(uvDerivatives.xz), length(uvDerivatives.yw));

        const bool2 invertLine = lineWidth > 0.5;
        const float2 targetWidth = select(lineWidth, 1.0 - lineWidth, invertLine);

        const float2 drawWidth = clamp(targetWidth, uvLengthDerivatives, 0.5);
        const float2 lineAntialiasing = max(uvLengthDerivatives, 0.000001) * 1.5;

        float2 gridUV = abs(fract(uv) * 2.0 - 1.0);
        gridUV = select(1.0 - gridUV, gridUV, invertLine);

        float2 gridSmooth = smoothstep(drawWidth + lineAntialiasing, drawWidth - lineAntialiasing, gridUV);
        gridSmooth *= saturate(targetWidth / drawWidth);

        gridSmooth = mix(gridSmooth, targetWidth, saturate(uvLengthDerivatives * 2.0 - 1.0));
        gridSmooth = select(gridSmooth, 1.0 - gridSmooth, invertLine);

        return mix(gridSmooth.x, 1.0, gridSmooth.y);
    }
} // namespace GridShader
