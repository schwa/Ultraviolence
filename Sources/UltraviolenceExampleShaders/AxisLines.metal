#include <metal_stdlib>
#include "include/UltraviolenceExampleShaders.h"
using namespace metal;

namespace AxisLines {

    struct VertexOut {
        float4 position [[position]];
        float4 color;
    };

    vertex VertexOut vertex_main(uint vertexID [[vertex_id]], constant AxisLinesUniforms& uniforms [[buffer(0)]]) {
        VertexOut out;

        float3 position;
        float4 color;

        switch(vertexID) {
            case 0: // X axis start
                position = float3(-uniforms.scale, 0, 0);
                color = float4(1, 0, 0, 1); // Red
                break;
            case 1: // X axis end
                position = float3(uniforms.scale, 0, 0);
                color = float4(1, 0, 0, 1); // Red
                break;
            case 2: // Y axis start
                position = float3(0, -uniforms.scale, 0);
                color = float4(0, 1, 0, 1); // Green
                break;
            case 3: // Y axis end
                position = float3(0, uniforms.scale, 0);
                color = float4(0, 1, 0, 1); // Green
                break;
            case 4: // Z axis start
                position = float3(0, 0, -uniforms.scale);
                color = float4(0, 0, 1, 1); // Blue
                break;
            case 5: // Z axis end
                position = float3(0, 0, uniforms.scale);
                color = float4(0, 0, 1, 1); // Blue
                break;
        }

        out.position = uniforms.mvpMatrix * float4(position, 1.0);
        out.position.xyz += uniforms.nudge;
        out.color = color;

        return out;
    }

    fragment float4 fragment_main(VertexOut in [[stage_in]]) {
        return in.color;
    }
}
