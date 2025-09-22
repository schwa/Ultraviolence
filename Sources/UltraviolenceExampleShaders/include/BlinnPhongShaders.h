#pragma once

#import "Support.h"
#import "Lighting.h"

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

