#import "include/UltraviolenceExampleShaders.h"
#import <metal_stdlib>

using namespace metal;

namespace TextureBillboard {

    [[ visible ]]
    float4 colorTransform(float4 colorA, float4 colorB, float2 textureCoordinate, constant void *parameters);

    struct VertexIn {
        float2 position [[attribute(0)]];
        float2 textureCoordinate [[attribute(1)]];
    };

    struct VertexOut {
        float4 position [[position]];
        float2 textureCoordinate;
    };

    // MARK: -

    // TODO: Move this into SHARED helper function - SHARED WITH TEXTUREBILLBOARD & FLATSHADER & BLINN PHONG
    float4 resolveSpecifiedColor(
        constant Texture2DSpecifierArgumentBuffer &specifier,
        float2 textureCoordinate
    ) {
        if (specifier.source == kColorSourceColor) {
            return float4(specifier.color, 1);
        } else if (specifier.source == kColorSourceTexture2D) {
            return specifier.texture2D.sample(specifier.sampler, textureCoordinate);
        } else if (specifier.source == kColorSourceTextureCube) {
            float2 uv = textureCoordinate;
            float3 direction;
            switch (specifier.slice) {
            case 0:
                direction = float3(1.0, uv.y, -uv.x);
                break; // +X
            case 1:
                direction = float3(-1.0, uv.y, uv.x);
                break; // -X
            case 2:
                direction = float3(uv.x, 1.0, -uv.y);
                break; // +Y
            case 3:
                direction = float3(uv.x, -1.0, uv.y);
                break; // -Y
            case 4:
                direction = float3(uv.x, uv.y, 1.0);
                break; // +Z
            case 5:
                direction = float3(-uv.x, uv.y, -1.0);
                break; // -Z
            }
            auto color = specifier.textureCube.sample(specifier.sampler, direction);
            color.a = 1.0;
            return color;
        } else if (specifier.source == kColorSourceDepth2D) {
            return specifier.depth2D.sample(specifier.sampler, textureCoordinate);
        } else {
            return float4(0.0, 0.0, 0.0, 0.0);
        }
    }

    // MARK: -

    [[vertex]] VertexOut vertex_main(const VertexIn in [[stage_in]]) {
        VertexOut out;
        out.position = float4(in.position, 0.0, 1.0);
        out.textureCoordinate = in.textureCoordinate;
        return out;
    }

    [[fragment]] float4 fragment_main(
        VertexOut in [[stage_in]],
        constant Texture2DSpecifierArgumentBuffer &specifierA [[buffer(0)]],
        constant Texture2DSpecifierArgumentBuffer &specifierB [[buffer(2)]],
        constant void *transformColorParameters [[buffer(4)]]

    ) {
        float4 colorA = resolveSpecifiedColor(specifierA, in.textureCoordinate);
        float4 colorB = resolveSpecifiedColor(specifierB, in.textureCoordinate);
        return colorTransform(colorA, colorB, in.textureCoordinate, transformColorParameters);
    }

    // MARK: -

    [[ stitchable ]]
    float4 colorTransformIdentity(float4 colorA, float4 colorB, float2 textureCoordinate, constant void *parameters) {
        return colorA;
    }

    [[ stitchable ]]
    float4 colorTransformDebug(float4 colorA, float4 colorB, float2 textureCoordinate, constant void *parameters) {
        return float4(1, 0, 1, 1);
    }

    [[ stitchable ]]
    float4 colorTransformYCbCrToRGB(float4 colorA, float4 colorB, float2 textureCoordinate, constant void *parameters) {
            // From: https://developer.apple.com/documentation/arkit/displaying-an-ar-experience-with-metal
            // ARKit provides Y in colorA (r8Unorm) and CbCr in colorB (rg8Unorm)
            // colorA.r contains Y (luminance)
            // colorB.rg contains Cb and Cr (chrominance)

           const float4x4 ycbcrToRGBTransform = float4x4(
               float4(+1.0000f, +1.0000f, +1.0000f, +0.0000f),
               float4(+0.0000f, -0.3441f, +1.7720f, +0.0000f),
               float4(+1.4020f, -0.7141f, +0.0000f, +0.0000f),
               float4(-0.7010f, +0.5291f, -0.8860f, +1.0000f)
           );

           // Sample Y and CbCr textures to get the YCbCr color at the given texture coordinate.
           float4 ycbcr = float4(colorA.r, colorB.rg, 1.0);

           // Return the converted RGB color.
           return ycbcrToRGBTransform * ycbcr;
    }

    [[ stitchable ]]
    float4 colorTransformBGRAToRGBA(float4 colorA, float4 colorB, float2 textureCoordinate, constant void *parameters) {
        // Simple BGRA to RGBA swizzle
        return colorA.bgra;
    }

} // namespace TextureBillboard
