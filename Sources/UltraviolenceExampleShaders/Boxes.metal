#include "UltraviolenceExampleShaders.h"
#include <metal_stdlib>
using namespace metal;

namespace Boxes {

    struct VertexOut {
        float4 position [[position]];
        float4 color;
    };

    // Box wireframe has 12 edges, each edge needs 2 vertices = 24 vertices
    // But we can draw it with line indices more efficiently
    vertex VertexOut vertex_main(
        uint vertexID [[vertex_id]],
        uint instanceID [[instance_id]],
        constant BoxesUniforms &uniforms [[buffer(0)]],
        constant BoxInstance *instances [[buffer(1)]]
    ) {
        VertexOut out;

        constant BoxInstance &box = instances[instanceID];

        // 8 vertices of a box
        float3 vertices[8] = {
            float3(box.min.x, box.min.y, box.min.z), // 0: min
            float3(box.max.x, box.min.y, box.min.z), // 1
            float3(box.max.x, box.max.y, box.min.z), // 2
            float3(box.min.x, box.max.y, box.min.z), // 3
            float3(box.min.x, box.min.y, box.max.z), // 4
            float3(box.max.x, box.min.y, box.max.z), // 5
            float3(box.max.x, box.max.y, box.max.z), // 6
            float3(box.min.x, box.max.y, box.max.z)  // 7
        };

        // Line indices for the 12 edges (24 vertices for line list)
        uint lineVertices[24] = {
            // Bottom face
            0, 1, 1, 2, 2, 3, 3, 0,
            // Top face
            4, 5, 5, 6, 6, 7, 7, 4,
            // Vertical edges
            0, 4, 1, 5, 2, 6, 3, 7
        };

        uint vertexIndex = lineVertices[vertexID];
        float3 position = vertices[vertexIndex];

        out.position = uniforms.mvpMatrix * float4(position, 1.0);
        out.position.xyz += uniforms.nudge;
        out.color = box.color;

        return out;
    }

    fragment float4 fragment_main(VertexOut in [[stage_in]]) {
        return in.color;
    }

} // namespace Boxes
