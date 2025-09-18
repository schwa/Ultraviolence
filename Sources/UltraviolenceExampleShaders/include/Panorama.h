#pragma once

#import "Support.h"

#import <simd/simd.h>

// Uniforms for panorama rendering
struct PanoramaUniforms {
    int showUV;           // 0 = show texture, 1 = show UV coordinates as colors
    float3 cameraLocation; // Camera location in model space
    float rotation;        // Panorama rotation in radians
};