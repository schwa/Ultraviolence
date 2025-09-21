#pragma once

#import "Support.h"

typedef UV_ENUM(int, LightType) {
    kLightTypeDirectional = 0,
    kLightTypePoint = 1,
    kLightTypeSpot = 2,
};

struct Light {
    LightType type;
    simd_float3 color;
    float intensity;
    float range;
};
typedef struct Light Light;

struct LightingArgumentBuffer {
    simd_float3 ambientLightColor;
    int lightCount;
    BUFFER(constant, Light *) lights;
    BUFFER(constant, simd_float3 *) lightPositions;
};
typedef struct LightingArgumentBuffer LightingArgumentBuffer;
