#include <metal_stdlib>
using namespace metal;

struct PointVertex {
    float3 position [[attribute(0)]];
    float3 color [[attribute(1)]];
};

struct PointVertexOut {
    float4 position [[position]];
    float3 color;
    float pointSize [[point_size]];
};

struct Uniforms {
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
    float pointSize;
};

vertex PointVertexOut pointCloudVertex(PointVertex in [[stage_in]], constant Uniforms &uniforms [[buffer(1)]]) {
    PointVertexOut out;

    // Transform position through view and projection
    float4 worldPos = float4(in.position, 1.0);
    float4 viewPos = uniforms.viewMatrix * worldPos;
    out.position = uniforms.projectionMatrix * viewPos;

    // Pass through color
    out.color = in.color;

    // Set point size (can be adjusted based on distance if needed)
    out.pointSize = uniforms.pointSize;

    return out;
}

fragment float4 pointCloudFragment(PointVertexOut in [[stage_in]], float2 pointCoord [[point_coord]]) {
    // Calculate distance from center of point sprite
    float2 fromCenter = pointCoord - float2(0.5);
    float dist = length(fromCenter);

    // Smooth circular points
    if (dist > 0.5) {
        discard_fragment();
    }

    // Add some shading to make points look spherical
    float intensity = 1.0 - dist * 1.5;
    intensity = saturate(intensity);

    return float4(in.color * intensity, 1.0);
}