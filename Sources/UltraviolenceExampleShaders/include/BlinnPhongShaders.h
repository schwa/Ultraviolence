#pragma once

#import "Support.h"

// long ambientTexture, long ambientSampler
struct BlinnPhongMaterialArgumentBuffer {
    ColorSource ambientSource;
    simd_float3 ambientColor;
    TEXTURE2D(float, access::sample)
    ambientTexture;
    SAMPLER ambientSampler;

    ColorSource diffuseSource;
    simd_float3 diffuseColor;
    TEXTURE2D(float, access::sample)
    diffuseTexture;
    SAMPLER diffuseSampler;

    ColorSource specularSource;
    simd_float3 specularColor;
    TEXTURE2D(float, access::sample)
    specularTexture;
    SAMPLER specularSampler;

    float shininess;
};

// MARK: -

typedef UV_ENUM(int, BlinnPhongLightType) {
    kBlinnPhongLightTypeDirectional = 0,
    kBlinnPhongLightTypePoint = 1,
    kBlinnPhongLightTypeSpot = 2,
};


struct BlinnPhongLight {
    BlinnPhongLightType type;
    simd_float3 position;
    simd_float3 color;
    float intensity;
};
typedef struct BlinnPhongLight BlinnPhongLight;

struct BlinnPhongLightingModelArgumentBuffer {
    int lightCount;
    simd_float3 ambientLightColor; // TODO
    BUFFER(constant, BlinnPhongLight *)
    lights;
};
