#pragma once

#import "Support.h"

// long ambientTexture, long ambientSampler
struct BlinnPhongMaterialArgumentBuffer {
    ColorSource ambientSource;
    simd_float3 ambientColor;
    TEXTURE(float, access::sample) ambientTexture;
    SAMPLER ambientSampler;

    ColorSource diffuseSource;
    simd_float3 diffuseColor;
    TEXTURE(float, access::sample) diffuseTexture;
    SAMPLER diffuseSampler;

    ColorSource specularSource;
    simd_float3 specularColor;
    TEXTURE(float, access::sample) specularTexture;
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

// MARK: -

struct Transforms {
    simd_float4x4 modelMatrix;
    simd_float4x4 cameraMatrix;
    simd_float4x4 viewMatrix;
    simd_float4x4 projectionMatrix;
    simd_float4x4 modelViewMatrix;
    simd_float4x4 modelViewProjectionMatrix;
    simd_float3x3 modelNormalMatrix;
};

