#pragma once

#import <simd/simd.h>

struct SDFUniforms {
    float time;
    simd_float2 resolution;
    simd_float3 cameraPos;
    simd_float3 lightPos;
    simd_float4x4 projectionMatrix;
    simd_float4x4 viewMatrix;
    int showDepth;
};