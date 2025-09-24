#import "UltraviolenceExampleShaders.h"
#import <metal_stdlib>

using namespace metal;

namespace TextureBillboard {

    [[visible]] float4
    colorTransform(float4 colorA, float4 colorB, float2 textureCoordinate, constant void *parameters);

    struct VertexIn {
        float2 position [[attribute(0)]];
        float2 textureCoordinate [[attribute(1)]];
    };

    struct VertexOut {
        float4 position [[position]];
        float2 textureCoordinate;
    };

    // MARK: -

    [[vertex]] VertexOut vertex_main(const VertexIn in [[stage_in]]) {
        VertexOut out;
        out.position = float4(in.position, 0.0, 1.0);
        out.textureCoordinate = in.textureCoordinate;
        return out;
    }

    [[fragment]] float4 fragment_main(
        VertexOut in [[stage_in]],
        constant ColorSourceArgumentBuffer &specifierA [[buffer(0)]],
        constant ColorSourceArgumentBuffer &specifierB [[buffer(2)]],
        constant void *transformColorParameters [[buffer(4)]]

    ) {
        float4 colorA = specifierA.resolve(in.textureCoordinate);
        float4 colorB = specifierB.resolve(in.textureCoordinate);
        return colorTransform(colorA, colorB, in.textureCoordinate, transformColorParameters);
    }

    // MARK: -

    [[stitchable]] float4
    colorTransformIdentity(float4 colorA, float4 colorB, float2 textureCoordinate, constant void *parameters) {
        return colorA;
    }

    [[stitchable]] float4
    colorTransformDebug(float4 colorA, float4 colorB, float2 textureCoordinate, constant void *parameters) {
        return float4(1, 0, 1, 1);
    }

    [[stitchable]] float4
    colorTransformYCbCrToRGB(float4 colorA, float4 colorB, float2 textureCoordinate, constant void *parameters) {
        // From: https://developer.apple.com/documentation/arkit/displaying-an-ar-experience-with-metal
        // ARKit provides Y in colorA (r8Unorm) and CbCr in colorB (rg8Unorm)
        // colorA.r contains Y (luminance)
        // colorB.rg contains Cb and Cr (chrominance)

        const float4x4 ycbcrToRGBTransform = float4x4(
            float4(+1.0000f, +1.0000f, +1.0000f, +0.0000f), float4(+0.0000f, -0.3441f, +1.7720f, +0.0000f),
            float4(+1.4020f, -0.7141f, +0.0000f, +0.0000f), float4(-0.7010f, +0.5291f, -0.8860f, +1.0000f)
        );

        // Sample Y and CbCr textures to get the YCbCr color at the given texture coordinate.
        float4 ycbcr = float4(colorA.r, colorB.rg, 1.0);

        // Return the converted RGB color.
        return ycbcrToRGBTransform * ycbcr;
    }

    [[stitchable]] float4
    colorTransformBGRAToRGBA(float4 colorA, float4 colorB, float2 textureCoordinate, constant void *parameters) {
        // Simple BGRA to RGBA swizzle
        return colorA.bgra;
    }

} // namespace TextureBillboard
