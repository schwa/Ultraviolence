#pragma once

#import "Support.h"

typedef UV_ENUM(int, ColorSourceType){
    kColorSourceTypeColor = 0,
    kColorSourceTypeTexture2D = 1,
    kColorSourceTypeTextureCube = 2,
    kColorSourceTypeDepth2D = 3,
};

struct ColorSourceArgumentBuffer {
    ColorSourceType source;
    simd_float3 color;
    TEXTURE2D(float, access::sample) texture2D;
    TEXTURECUBE(float, access::sample) textureCube;
    uint slice;
    DEPTH2D(float, access::sample) depth2D;
    SAMPLER sampler;

#if defined(__METAL_VERSION__)
    inline float4 resolve(float2 textureCoordinate) constant;
#endif
};
typedef struct ColorSourceArgumentBuffer ColorSourceArgumentBuffer;

#if defined(__METAL_VERSION__)
inline float4 ColorSourceArgumentBuffer::resolve(float2 textureCoordinate) constant {
    if (source == kColorSourceTypeColor) {
        return float4(color, 1);
    } else if (source == kColorSourceTypeTexture2D) {
        return texture2D.sample(sampler, textureCoordinate);
    } else if (source == kColorSourceTypeTextureCube) {
        float2 uv = textureCoordinate;
        float3 direction;
        switch (slice) {
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
        auto color = textureCube.sample(sampler, direction);
        color.a = 1.0;
        return color;
    } else if (source == kColorSourceTypeDepth2D) {
        return depth2D.sample(sampler, textureCoordinate);
    } else {
        return float4(0.0, 0.0, 0.0, 0.0);
    }
}

#endif
