#pragma once

#import "Support.h"

#import <simd/simd.h>

// Material properties for PBR
// Must match Swift ShaderMaterial struct exactly
struct PBRMaterial {
    float3 albedo;
    float metallic;
    float roughness;
    float ao;
    float3 emissive;
    float emissiveIntensity;
    float clearcoat;
    float clearcoatRoughness;
    // Cheap subsurface scattering approximation properties
    float softScattering;
    float3 softScatteringDepth;
    float3 softScatteringTint;
};

// Uniforms for model transformation
struct PBRUniforms {
    struct PBRMaterial material;
    float4x4 modelMatrix;
    float3x3 normalMatrix;
};

// Per-view uniforms
struct PBRAmplifiedUniforms {
    float4x4 viewProjectionMatrix;
    float3 cameraPosition;
};
