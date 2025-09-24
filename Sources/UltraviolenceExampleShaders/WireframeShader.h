#pragma once

#import "Support.h"
#import <simd/simd.h>

struct WireframeUniforms {
    float4x4 modelViewProjectionMatrix;
    float4 wireframeColor;
};
