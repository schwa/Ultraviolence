#import <metal_logging>
#import <metal_stdlib>

using namespace metal;

namespace AppleEventLogoShaders {

    struct HeatParameters {
        float2 mousePosition;  // Normalized mouse position (0-1) - 8 bytes (offset: 0)
        float2 mouseDirection; // Mouse movement direction - 8 bytes (offset: 8)
        float heatIntensity;   // Current heat level (0-1.3) - 4 bytes (offset: 16)
        float radius;          // Effect radius in pixels - 4 bytes (offset: 20)
        float fadeDamping;     // Fade factor for previous frame (e.g., 0.95) - 4 bytes (offset: 24)
        float sizeDamping;     // Size damping factor - 4 bytes (offset: 28)
        uint2 textureSize;     // Texture dimensions - 8 bytes (offset: 32)
        float isInteracting;   // 1.0 if mouse is down/moving, 0.0 otherwise - 4 bytes (offset: 40)
        uint _padding_final;   // Padding to match Swift struct size - 4 bytes (offset: 44) - total: 48 bytes
    };

    [[kernel]] void heatup(
        texture2d<float, access::read> previousTexture [[texture(0)]],
        texture2d<float, access::write> currentTexture [[texture(1)]],
        constant HeatParameters &heatParameters [[buffer(0)]],
        uint2 gid [[thread_position_in_grid]]
    ) {
        // Ensure we're within texture bounds
        if (gid.x >= heatParameters.textureSize.x || gid.y >= heatParameters.textureSize.y) {
            return;
        }

        // Calculate aspect ratio
        float aspect = float(heatParameters.textureSize.x) / float(heatParameters.textureSize.y);

        // Convert thread position to normalized coordinates (0-1)
        float2 uv = float2(gid) / float2(heatParameters.textureSize);

        // Adjust mouse position and UV for aspect ratio
        float2 mousePos = heatParameters.mousePosition;
        mousePos.y /= aspect;
        float2 adjustedUv = uv;
        adjustedUv.y /= aspect;

        // Calculate distance from mouse position
        float dist = distance(mousePos, adjustedUv) / (heatParameters.radius / float(heatParameters.textureSize.x));

        // Smoothstep falloff (matching the GLSL shader's behavior)
        // In the original: smoothstep(uRadius.x, uRadius.y, dist) where x=0.0, y=1.0
        dist = smoothstep(0.0, 1.0, dist);

        // Calculate direction offset for distortion effects
        float2 offset = heatParameters.mouseDirection * (1.0 - dist);

        // Sample previous frame's value with offset
        // Note: Since Metal doesn't have built-in texture sampling in compute shaders,
        // we'll use integer coordinates with clamping
        int2 sampleCoord =
            int2(uv * float2(heatParameters.textureSize) + offset * 0.01 * float2(heatParameters.textureSize));
        sampleCoord = clamp(sampleCoord, int2(0), int2(heatParameters.textureSize) - 1);

        float4 previousValue = previousTexture.read(uint2(sampleCoord));

        // Apply fade damping to previous value
        float4 color = previousValue * heatParameters.fadeDamping;

        // Store movement direction in RG channels (matching the JS demo)
        color.r += offset.x;
        color.g += offset.y;

        // Clamp direction values to prevent overflow
        color.rg = clamp(color.rg, -1.0, 1.0);

        // Add heat to blue channel based on interaction and distance
        float heatAddition = heatParameters.heatIntensity * (1.0 - dist) * heatParameters.isInteracting;
        color.b += heatAddition;

        // Note: No explicit clamp on heat since it naturally decays

        // Write result to current texture
        currentTexture.write(color, gid);
    }

} // namespace AppleEventLogoShaders
