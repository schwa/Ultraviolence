#import <metal_stdlib>

using namespace metal;

namespace ThermalVideoBlend {

    [[kernel]] void blendThermalWithVideo(
        texture2d<float, access::read> thermalTexture [[texture(0)]], // Colored thermal effect
        texture2d<float, access::read> videoTexture [[texture(1)]],   // Video frame
        texture2d<float, access::read> heatTexture [[texture(2)]],    // Raw heat values
        texture2d<float, access::write> outputTexture [[texture(3)]], // Final output
        constant float &videoBlendAmount [[buffer(0)]],               // How much video to blend (0-1)
        uint2 gid [[thread_position_in_grid]]
    ) {
        // Check bounds
        if (gid.x >= outputTexture.get_width() || gid.y >= outputTexture.get_height()) {
            return;
        }

        // Read textures
        float4 thermal = thermalTexture.read(gid);
        float4 heat = heatTexture.read(gid);

        // Sample video with normalized coordinates
        float2 videoSize = float2(videoTexture.get_width(), videoTexture.get_height());
        float2 outputSize = float2(outputTexture.get_width(), outputTexture.get_height());

        // Calculate UV for video sampling
        float2 uv = float2(gid) / outputSize;
        // Don't flip Y - use normal coordinates
        uint2 videoCoord = uint2(uv * videoSize);
        videoCoord = clamp(videoCoord, uint2(0), uint2(videoSize) - 1);

        float4 video = videoTexture.read(videoCoord);

        // Get heat intensity from blue channel
        float heatIntensity = heat.b;

        // Use video luminance as base temperature (like the JS version)
        float videoLuminance = dot(video.rgb, float3(0.299, 0.587, 0.114));
        float baseTemperature = pow(videoLuminance, 0.8); // Power curve for contrast

        // Combine base temperature from video with interactive heat
        float totalTemperature = saturate(baseTemperature * 0.5 + heatIntensity);

        // The thermal effect should always be visible where there's video content
        // This ensures the logo has color even without mouse interaction
        float4 result = thermal;

        // Modulate by the combined temperature
        result.rgb *= max(totalTemperature, 0.1); // Minimum visibility

        // Ensure we respect the mask (thermal alpha contains mask)
        result.a = thermal.a;

        // Write result
        outputTexture.write(result, gid);
    }

    // Simpler version without video for testing
    [[kernel]] void passthroughThermal(
        texture2d<float, access::read> thermalTexture [[texture(0)]],
        texture2d<float, access::write> outputTexture [[texture(1)]],
        uint2 gid [[thread_position_in_grid]]
    ) {
        if (gid.x >= outputTexture.get_width() || gid.y >= outputTexture.get_height()) {
            return;
        }

        float4 color = thermalTexture.read(gid);
        outputTexture.write(color, gid);
    }

} // namespace ThermalVideoBlend