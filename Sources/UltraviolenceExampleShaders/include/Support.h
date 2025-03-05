#pragma once

#import <simd/simd.h>

#if defined(__METAL_VERSION__)
#import <metal_stdlib>
#define ATTRIBUTE(INDEX) [[attribute(INDEX)]]
#define TEXTURE2D(TYPE, ACCESS) texture2d<TYPE, ACCESS>
#define SAMPLER sampler
#define BUFFER(ADDRESS_SPACE, TYPE) ADDRESS_SPACE TYPE
using namespace metal;
#else
#import <Metal/Metal.h>
#define ATTRIBUTE(INDEX)
#define TEXTURE2D(TYPE, ACCESS) MTLResourceID
#define SAMPLER MTLResourceID
#define BUFFER(ADDRESS_SPACE, TYPE) TYPE
#endif

// Copied from <CoreFoundation/CFAvailability.h>
#define __UV_ENUM_ATTRIBUTES __attribute__((enum_extensibility(open)))
#define __UV_ANON_ENUM(_type)             enum __UV_ENUM_ATTRIBUTES : _type
#define __UV_NAMED_ENUM(_type, _name)     enum __UV_ENUM_ATTRIBUTES _name : _type _name; enum _name : _type
#define __UV_ENUM_GET_MACRO(_1, _2, NAME, ...) NAME
#define UV_ENUM(...) __UV_ENUM_GET_MACRO(__VA_ARGS__, __UV_NAMED_ENUM, __UV_ANON_ENUM, )(__VA_ARGS__)

// TODO: Rename?
typedef UV_ENUM (int, ColorSource) {
    kColorSourceColor = 0,
    kColorSourceTexture = 1,
};

struct Texture2DSpecifierArgumentBuffer {
    ColorSource source;
    // TODO: use a union?
    simd_float4 color;
    TEXTURE2D(float, access::sample) texture;
    SAMPLER sampler;
};

