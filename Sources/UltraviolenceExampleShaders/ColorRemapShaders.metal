#import <metal_stdlib>

using namespace metal;

namespace ColorRemap {

    // TODO: This is WAY TOO specific to the example it's used in.
    [[kernel]] void colorRemap(
        texture2d<float, access::read> inputTexture [[texture(0)]],
        texture2d<float, access::write> outputTexture [[texture(1)]],
        texture1d<float, access::sample> gradientTexture [[texture(2)]],
        texture2d<float, access::sample> maskTexture [[texture(3)]],
        texture2d<float, access::read> videoTexture [[texture(4)]],
        constant float &power [[buffer(0)]],
        uint2 gid [[thread_position_in_grid]]
    ) {
        // Check bounds
        if (gid.x >= outputTexture.get_width() || gid.y >= outputTexture.get_height()) {
            return;
        }

        // Read heat value from input texture
        float4 inputValue = inputTexture.read(gid);
        float heatIntensity = inputValue.b; // Heat is stored in blue channel

        // Read video and use its luminance as base temperature
        float2 videoSize = float2(videoTexture.get_width(), videoTexture.get_height());
        float2 outputSize = float2(outputTexture.get_width(), outputTexture.get_height());
        float2 uv = float2(gid) / outputSize;
        // Don't flip Y - use normal coordinates
        uint2 videoCoord = uint2(uv * videoSize);
        videoCoord = clamp(videoCoord, uint2(0), uint2(videoSize) - 1);
        float4 videoColor = videoTexture.read(videoCoord);

        // Calculate base temperature from video luminance
        float videoLuminance = dot(videoColor.rgb, float3(0.299, 0.587, 0.114));
        float baseTemperature = pow(videoLuminance, power);

        // Combine base temperature with interactive heat
        float intensity = saturate(baseTemperature + heatIntensity);

        // Sample gradient texture at this intensity
        constexpr sampler gradientSampler(coord::normalized, address::clamp_to_edge, filter::linear);
        float4 color = gradientTexture.sample(gradientSampler, intensity);

        // Sample mask texture
        constexpr sampler maskSampler(coord::normalized, address::clamp_to_edge, filter::linear);
        float2 maskUV = float2(gid) / float2(outputTexture.get_width(), outputTexture.get_height());
        // Don't flip Y - use normal coordinates
        float4 maskValue = maskTexture.sample(maskSampler, maskUV);

        // Use the green channel from the mask (since the Apple logo is green)
        float maskAlpha = maskValue.g;

        // Apply mask to color
        color *= maskAlpha;

        // Write to output
        outputTexture.write(color, gid);
    }

    // Alternative kernel that uses discrete color bands instead of smooth gradient
    [[kernel]] void colorRemapBanded(
        texture2d<float, access::read> inputTexture [[texture(0)]],
        texture2d<float, access::write> outputTexture [[texture(1)]],
        texture1d<float, access::sample> gradientTexture [[texture(2)]],
        constant float &power [[buffer(0)]],
        constant float &bands [[buffer(1)]],
        uint2 gid [[thread_position_in_grid]]
    ) {
        // Check bounds
        if (gid.x >= outputTexture.get_width() || gid.y >= outputTexture.get_height()) {
            return;
        }

        // Read input value
        float4 inputValue = inputTexture.read(gid);
        float intensity = inputValue.b;

        // Apply power curve
        intensity = pow(intensity, power);
        intensity = saturate(intensity);

        // Quantize to bands
        if (bands > 1.0) {
            intensity = floor(intensity * bands) / (bands - 1.0);
        }

        // Sample gradient texture
        constexpr sampler gradientSampler(coord::normalized, address::clamp_to_edge, filter::linear);
        float4 color = gradientTexture.sample(gradientSampler, intensity);

        // Write to output
        outputTexture.write(color, gid);
    }

} // namespace ColorRemap
