#include <metal_stdlib>
using namespace metal;

namespace VCRDistortion {

struct FrameUniforms {
    uint32_t index;
    float time;
    float deltaTime;
    uint2 viewportSize;
};

struct VCRParameters {
    // Image distortion
    float curvature;
    float skip;
    float image_flicker;

    // Vignette
    float vignette_flicker_speed;
    float vignette_strength;

    // Scanlines
    float small_scanlines_speed;
    float small_scanlines_proximity;
    float small_scanlines_opacity;
    float scanlines_opacity;
    float scanlines_speed;
    float scanline_thickness;
    float scanlines_spacing;

    // Time-based effects
    float noise_amount;
    float chromatic_aberration;
};

// Helper functions
float rand(float2 co) {
    return fract(sin(dot(co.xy, float2(12.9898, 78.233))) * 43758.5453);
}

float noise(float2 p, float time, texture2d<float> noiseTexture, sampler noiseSampler) {
    float2 timeOffset = float2(time, 2.0 * time) * 8.0;
    float s = noiseTexture.sample(noiseSampler, timeOffset + p).x;
    return s * s;
}

float onOff(float a, float b, float c, float time) {
    return step(c, sin(time + a * cos(time * b)));
}

float2 apply_distortion(float2 uv, float curvature) {
    // When curvature is 0, no distortion
    // When curvature is 10, maximum distortion
    if (curvature < 0.01) return uv;

    float2 centered = uv * 2.0 - 1.0;
    float strength = curvature / 10.0;  // Normalize to 0-1 range
    float2 offset = centered.yx * strength;
    return uv + centered * offset * offset;
}

float vignette(float2 uv, float strength) {
    float2 centered = uv - 0.5;
    float dist = length(centered);
    return 1.0 - strength * dist * dist;
}

kernel void vcr_distortion(
    texture2d<float, access::sample> inputTexture [[texture(0)]],
    texture2d<float, access::write> outputTexture [[texture(1)]],
    texture2d<float> noiseTexture [[texture(2)]],
    constant VCRParameters& params [[buffer(0)]],
    constant FrameUniforms& frameUniforms [[buffer(1)]],
    uint2 gid [[thread_position_in_grid]]
) {
    // Get texture dimensions
    float2 textureSize = float2(outputTexture.get_width(), outputTexture.get_height());

    // Early exit for out of bounds
    if (gid.x >= textureSize.x || gid.y >= textureSize.y) {
        return;
    }

    // Normalized coordinates
    float2 uv = float2(gid) / textureSize;

    // Create sampler
    constexpr sampler linearSampler(mag_filter::linear, min_filter::linear, address::clamp_to_edge);
    constexpr sampler noiseSampler(mag_filter::linear, min_filter::linear, address::repeat);

    // Apply curvature distortion
    float2 distorted_uv = apply_distortion(uv, params.curvature);

    // Add horizontal shift effect (VHS tracking)
    float shift = 0.0;
    if (params.skip > 0.0) {
        float onOffValue = onOff(0.05, 4.0, 0.5, frameUniforms.time);
        shift = sin(frameUniforms.time * 10.0) * sin(frameUniforms.time * 0.5) * sin(frameUniforms.time * 1.0) * 0.005 * onOffValue;
        shift *= params.skip;
        distorted_uv.x += shift;
    }

    // Sample the input texture
    float4 color = inputTexture.sample(linearSampler, distorted_uv);

    // Apply image flicker
    if (params.image_flicker > 0.0) {
        float flicker = 1.0 + params.image_flicker * sin(frameUniforms.time * 10.0) * 0.05;
        color.rgb *= flicker;
    }

    // Apply vignette
    float vignetteValue = vignette(uv, params.vignette_strength);

    // Animated vignette flicker
    if (params.vignette_flicker_speed > 0.0) {
        float vignetteFlicker = 1.0 + sin(frameUniforms.time * params.vignette_flicker_speed * 10.0) * 0.1;
        vignetteValue *= vignetteFlicker;
    }

    color.rgb *= vignetteValue;

    // Add scanlines
    if (params.scanlines_opacity > 0.0) {
        float scanline = sin((uv.y + frameUniforms.time * params.scanlines_speed * 0.01) *
                             textureSize.y * params.scanlines_spacing * 0.5) * 0.5 + 0.5;
        scanline = smoothstep(params.scanline_thickness, 1.0, scanline);
        color.rgb *= mix(1.0, scanline, params.scanlines_opacity);
    }

    // Add small fast-moving scanlines
    if (params.small_scanlines_opacity > 0.0) {
        float smallScanline = sin((uv.y - frameUniforms.time * params.small_scanlines_speed * 0.1) *
                                  textureSize.y * params.small_scanlines_proximity) * 0.5 + 0.5;
        smallScanline = pow(smallScanline, 3.0);
        color.rgb *= mix(1.0, 1.0 - smallScanline, params.small_scanlines_opacity * 0.2);
    }

    // Add noise
    if (params.noise_amount > 0.0) {
        float noiseValue = noise(uv * 2.0, frameUniforms.time, noiseTexture, noiseSampler);
        color.rgb = mix(color.rgb, float3(noiseValue), params.noise_amount * 0.05);
    }

    // Add chromatic aberration for extra VHS feel
    if (params.chromatic_aberration > 0.0) {
        float2 caOffset = float2(0.002, 0.0) * sin(frameUniforms.time * 5.0) * params.chromatic_aberration;
        float r = inputTexture.sample(linearSampler, distorted_uv + caOffset).r;
        float b = inputTexture.sample(linearSampler, distorted_uv - caOffset).b;
        color.r = mix(color.r, r, params.chromatic_aberration * 0.3);
        color.b = mix(color.b, b, params.chromatic_aberration * 0.3);
    }

    // Write output
    outputTexture.write(color, gid);
}

} // namespace VCRDistortion