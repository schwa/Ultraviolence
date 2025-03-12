#pragma once

#import "Support.h"

// long ambientTexture, long ambientSampler
struct BlinnPhongMaterialArgumentBuffer {
    ColorSource ambientSource;
    simd_float3 ambientColor;
    TEXTURE2D(float, access::sample) ambientTexture;
    SAMPLER ambientSampler;

    ColorSource diffuseSource;
    simd_float3 diffuseColor;
    TEXTURE2D(float, access::sample) diffuseTexture;
    SAMPLER diffuseSampler;

    ColorSource specularSource;
    simd_float3 specularColor;
    TEXTURE2D(float, access::sample) specularTexture;
    SAMPLER specularSampler;

    float shininess;
};

// MARK: -

struct BlinnPhongLight {
    simd_float3 lightPosition;
    simd_float3 lightColor;
    float lightPower;
};
typedef struct BlinnPhongLight BlinnPhongLight;

struct BlinnPhongLightingModelArgumentBuffer {
    float screenGamma; // TODO: Move
    int lightCount;
    simd_float3 ambientLightColor; // TODO
    BUFFER(constant, BlinnPhongLight *) lights;
};
