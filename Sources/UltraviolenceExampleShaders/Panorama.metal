#import "UltraviolenceExampleShaders.h"
#import "Panorama.h"
#include <metal_stdlib>

using namespace metal;

namespace Panorama {

// MARK: - Main Panorama Viewer

struct SphereVertexIn {
    float3 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
    float2 texCoord [[attribute(2)]];  // We won't use this, but it's in the vertex descriptor
};

struct SphereVertexOut {
    float4 position [[position]];
    float3 modelSpacePosition;  // Pass model-space position for UV calculation in fragment
};

[[vertex]] SphereVertexOut vertex_main(const SphereVertexIn in [[stage_in]], constant Transforms &transforms [[buffer(4)]]) {
    SphereVertexOut out;

    // Pass model-space position to fragment shader
    out.modelSpacePosition = in.position;

    // Transform position for rendering
    float4 worldPosition = transforms.modelMatrix * float4(in.position, 1.0);
    float4 viewPosition = transforms.viewMatrix * worldPosition;
    out.position = transforms.projectionMatrix * viewPosition;

    return out;
}

float2 uv_of_camera(float3 modelSpacePosition, float3 location, float rotation) {
    const float3 d = modelSpacePosition - location;
    const float r = length(d.xz);
    const float u = fract((atan2(d.x, -d.z) / M_PI_F + 1.0) * 0.5 - rotation / (M_PI_F * 2.0));
    const float v = atan2(d.y, r) / M_PI_F + 0.5;
    return float2(u, v);
}

[[fragment]] float4 fragment_main(SphereVertexOut in [[stage_in]],
                                  texture2d<float> panoramaTexture [[texture(0)]],
                                  constant PanoramaUniforms* uniforms [[buffer(0)]]) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear, address::repeat);

    // Calculate UV using the camera function with location and rotation support
    float3 location = uniforms ? uniforms->cameraLocation : float3(0, 0, 0);
    float rotation = uniforms ? uniforms->rotation : 0.0;
    float2 uv = uv_of_camera(in.modelSpacePosition, location, rotation);
    uv.y = 1.0 - uv.y; // Flip V for correct orientation

    // Check debug mode
    if (uniforms && uniforms->showUV) {
        // Show UV coordinates as colors (R=U, G=V, B=0)
        return float4(uv.x, uv.y, 0.0, 1.0);
    } else {
        // Sample the panorama texture
        float4 color = panoramaTexture.sample(textureSampler, uv);
        return color;
    }
}

// MARK: - Minimap

struct MinimapVertexIn {
    float3 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
};

struct MinimapVertexOut {
    float4 position [[position]];
    float2 texCoord;
};

[[vertex]] MinimapVertexOut minimap_vertex(const MinimapVertexIn in [[stage_in]]) {
    MinimapVertexOut out;
    out.position = float4(in.position, 1.0);
    out.texCoord = in.texCoord;
    return out;
}

[[fragment]] float4 minimap_fragment(MinimapVertexOut in [[stage_in]],
                                     texture2d<float> panoramaTexture [[texture(0)]]) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear, address::repeat);

    // Convert UV to centered coordinates
    float2 centered = (in.texCoord - 0.5) * 2.0;

    // Calculate distance from center
    float dist = length(centered);

    // If outside the circle, discard the fragment
    if (dist > 1.0) {
        discard_fragment();
    }

    // Use stereographic projection for the bottom hemisphere
    // This reduces the fisheye effect by projecting the sphere more naturally

    float angle = atan2(centered.y, centered.x);

    // Stereographic projection: map circle radius to sphere
    // This gives a more natural, less distorted view
    float r = dist;
    float theta = 2.0 * atan(r); // Stereographic mapping

    // Convert to spherical coordinates (looking up from south pole)
    float latitude = -(M_PI_F / 2.0 - theta);

    // Convert spherical coordinates to equirectangular UV coordinates
    float u = (angle + M_PI_F) / (2.0 * M_PI_F);
    float v = 1.0 - ((latitude + M_PI_F / 2.0) / M_PI_F);

    // Sample the panorama texture
    float4 color = panoramaTexture.sample(textureSampler, float2(u, v));

    return color;
}

}
