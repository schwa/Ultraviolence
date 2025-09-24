#pragma once

#import "ColorSource.h"
#import "Support.h"

struct PBRMaterialArgumentBuffer {
    ColorSourceArgumentBuffer albedo;
    TEXTURE2D(float, access::sample) normal;
    ColorSourceArgumentBuffer metallic;
    ColorSourceArgumentBuffer roughness;
    ColorSourceArgumentBuffer ambientOcclusion;
    ColorSourceArgumentBuffer emissive;
    float emissiveIntensity;
    float clearcoat;          // TODO: ColorSourceArgumentBuffer
    float clearcoatRoughness; // TODO: ColorSourceArgumentBuffer
    float softScattering;
    float3 softScatteringDepth;
    float3 softScatteringTint;
};

// Uniforms for model transformation
struct PBRUniforms {
    float4x4 modelMatrix;
    float3x3 normalMatrix;
};

// Per-view uniforms
struct PBRAmplifiedUniforms {
    float4x4 viewProjectionMatrix;
    float3 cameraPosition;
};
