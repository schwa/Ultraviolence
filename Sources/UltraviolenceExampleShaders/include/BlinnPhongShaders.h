#pragma once

#import <simd/simd.h>

#if defined(__METAL_VERSION__)
#import <metal_stdlib>
#define ATTRIBUTE(INDEX) [[attribute(INDEX)]]
#define TEXTURE(TYPE, ACCESS) texture2d<TYPE, ACCESS>
#define SAMPLER sampler
#define BUFFER(ADDRESS_SPACE, TYPE) ADDRESS_SPACE TYPE
using namespace metal;
#else
#import <Metal/Metal.h>
#define ATTRIBUTE(INDEX)
#define TEXTURE(TYPE, ACCESS) MTLResourceID
#define SAMPLER MTLResourceID
#define BUFFER(ADDRESS_SPACE, TYPE) TYPE
#endif

enum ColorSource {
    texture = 0,
    color = 1,
};
typedef enum ColorSource ColorSource;

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

struct Vertex {
    simd_float3 position ATTRIBUTE(0);
    simd_float3 normal ATTRIBUTE(1);
    simd_float2 textureCoordinate ATTRIBUTE(2);
};

struct Transforms {
    simd_float4x4 modelMatrix;
    simd_float4x4 cameraMatrix;
    simd_float4x4 viewMatrix;
    simd_float4x4 projectionMatrix;
    simd_float4x4 modelViewMatrix;
    simd_float4x4 modelViewProjectionMatrix;
    simd_float3x3 modelNormalMatrix;

};

