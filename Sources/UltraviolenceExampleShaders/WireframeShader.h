#pragma once

#import <simd/simd.h>
#import "Support.h"

struct WireframeUniforms {
    float4x4 modelViewProjectionMatrix;
    float4 wireframeColor;
};
