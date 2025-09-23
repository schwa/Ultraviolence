#pragma once

#import "ColorSpecifier.h"
#import "Support.h"

struct PBRMaterialArgumentBuffer {
    ColorSpecifierArgumentBuffer albedo;
    TEXTURE2D(float, access::sample) normal;
    ColorSpecifierArgumentBuffer metallic;
    ColorSpecifierArgumentBuffer roughness;
    ColorSpecifierArgumentBuffer ambientOcclusion;
    ColorSpecifierArgumentBuffer emissive;
    float emissiveIntensity;
    float clearcoat; // TODO: ColorSpecifierArgumentBuffer
    float clearcoatRoughness; // TODO: ColorSpecifierArgumentBuffer
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
