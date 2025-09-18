#import <metal_stdlib>
#import "include/UltraviolenceExampleShaders.h"

using namespace metal;

[[ visible ]]
float4 colorAdjustFunction(float4 inputColor, float2 inputCoordinate, constant void *parameters);

namespace ColorAdjust {

    // TODO: Move
    float4 resolveSpecifiedColor(
        constant Texture2DSpecifierArgumentBuffer &specifier,
        float2 textureCoordinate,
        thread bool &discard
    ) {
        if (specifier.source == kColorSourceColor) {
            return float4(specifier.color, 1);
        } else if (specifier.source == kColorSourceTexture2D) {
            return specifier.texture2D.sample(specifier.sampler, textureCoordinate);
        } else if (specifier.source == kColorSourceDepth2D) {
            return specifier.depth2D.sample(specifier.sampler, textureCoordinate);
        } else {
            discard = true;
            return float4(0.0, 0.0, 0.0, 0.0);
        }
    }

    // TODO: Move
    float2 textureCoordinateForPixel(
        constant Texture2DSpecifierArgumentBuffer &specifier,
        uint2 position
    ) {
        if (specifier.source == kColorSourceTexture2D) {
            float2 size = float2(specifier.texture2D.get_width(), specifier.texture2D.get_height());
            return (float2(position) + 0.5) / size;
        }
        else if (specifier.source == kColorSourceDepth2D) {
            float2 size = float2(specifier.depth2D.get_width(), specifier.depth2D.get_height());
            return  (float2(position) + 0.5) / size;
        } else {
            return float2(0, 0);
        }
    }

    kernel void colorAdjust(
        constant Texture2DSpecifierArgumentBuffer &inputSpecifier [[buffer(0)]],
        constant void *inputParameters [[buffer(1)]],
        texture2d<float, access::read_write> outputTexture [[texture(0)]],
        uint2 thread_position_in_grid [[thread_position_in_grid]]
    ) {
        bool discard = false;
        const float2 textureCoordinate = textureCoordinateForPixel(inputSpecifier, thread_position_in_grid);
        const float4 inputColor = resolveSpecifiedColor(inputSpecifier, textureCoordinate, discard);
        // TODO: Make this a function pointer
//        float4 newColor = pow(inputColor, 50.0);;

        float4 newColor = colorAdjustFunction(inputColor, textureCoordinate, inputParameters);

        outputTexture.write(newColor, thread_position_in_grid);
    }
}
