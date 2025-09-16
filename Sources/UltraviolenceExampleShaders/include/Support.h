#pragma once

#import <simd/simd.h>

#if defined(__METAL_VERSION__)
#import <metal_stdlib>
#define ATTRIBUTE(INDEX) [[attribute(INDEX)]]
#define TEXTURE2D(TYPE, ACCESS) texture2d<TYPE, ACCESS>
#define DEPTH2D(TYPE, ACCESS) depth2d<TYPE, ACCESS>
#define TEXTURECUBE(TYPE, ACCESS) texturecube<TYPE, ACCESS>
#define SAMPLER sampler
#define BUFFER(ADDRESS_SPACE, TYPE) ADDRESS_SPACE TYPE
using namespace metal;
#else
#import <Metal/Metal.h>
#define ATTRIBUTE(INDEX)
#define TEXTURE2D(TYPE, ACCESS) MTLResourceID
#define DEPTH2D(TYPE, ACCESS) MTLResourceID
#define TEXTURECUBE(TYPE, ACCESS) MTLResourceID
#define SAMPLER MTLResourceID
#define BUFFER(ADDRESS_SPACE, TYPE) TYPE
#endif

// Copied from <CoreFoundation/CFAvailability.h>
#define __UV_ENUM_ATTRIBUTES __attribute__((enum_extensibility(open)))
#define __UV_ANON_ENUM(_type) enum __UV_ENUM_ATTRIBUTES : _type
#define __UV_NAMED_ENUM(_type, _name)                                                                                  \
    enum __UV_ENUM_ATTRIBUTES _name : _type _name;                                                                     \
    enum _name : _type
#define __UV_ENUM_GET_MACRO(_1, _2, NAME, ...) NAME
#define UV_ENUM(...) __UV_ENUM_GET_MACRO(__VA_ARGS__, __UV_NAMED_ENUM, __UV_ANON_ENUM, )(__VA_ARGS__)

typedef UV_ENUM(int, ColorSource){
    kColorSourceColor = 0,
    kColorSourceTexture2D = 1,
    kColorSourceTextureCube = 2,
    kColorSourceDepth2D = 3,
};

struct Texture2DSpecifierArgumentBuffer {
    ColorSource source;
    simd_float3 color;
    TEXTURE2D(float, access::sample) texture2D;
    TEXTURECUBE(float, access::sample) textureCube;
    DEPTH2D(float, access::sample) depth2D;
    SAMPLER sampler;
};

/// Universal transforms.
struct Transforms {
    simd_float4x4 modelMatrix;
    simd_float4x4 cameraMatrix;
    simd_float4x4 viewMatrix;
    simd_float4x4 projectionMatrix;
    simd_float4x4 modelViewMatrix;
    simd_float4x4 modelViewProjectionMatrix;
};

#if defined(__METAL_VERSION__)
inline float square(float x) {
    return x * x;
}

inline float3x3 extractNormalMatrix(float4x4 modelMatrix) {
    return float3x3(modelMatrix[0].xyz, modelMatrix[1].xyz, modelMatrix[2].xyz);
}
#endif
