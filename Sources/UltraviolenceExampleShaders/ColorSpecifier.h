#pragma once

#import "Support.h"

typedef UV_ENUM(int, ColorSource){
    kColorSourceColor = 0,
    kColorSourceTexture2D = 1,
    kColorSourceTextureCube = 2,
    kColorSourceDepth2D = 3,
};

struct ColorSpecifierArgumentBuffer {
    ColorSource source;
    simd_float3 color;
    TEXTURE2D(float, access::sample) texture2D;
    TEXTURECUBE(float, access::sample) textureCube;
    uint slice;
    DEPTH2D(float, access::sample) depth2D;
    SAMPLER sampler;
};
typedef struct ColorSpecifierArgumentBuffer ColorSpecifierArgumentBuffer;

#if defined(__METAL_VERSION__)
static inline float4 resolveSpecifiedColor(
    constant ColorSpecifierArgumentBuffer &specifier,
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
#endif
