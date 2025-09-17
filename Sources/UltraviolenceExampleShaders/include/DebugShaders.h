#pragma once

#import "Support.h"

typedef UV_ENUM(int, DebugShadersMode) {
    kDebugShadersModeNormal = 0,
    kDebugShadersModeTexCoord = 1,
    kDebugShadersModeTangent = 2,
    kDebugShadersModeBitangent = 3,
    kDebugShadersModeWorldPosition = 4,
    kDebugShadersModeLocalPosition = 5,
    kDebugShadersModeUVDistortion = 6,
    kDebugShadersModeTBNMatrix = 7,
    kDebugShadersModeVertexID = 8,
    kDebugShadersModeFaceNormal = 9,
    kDebugShadersModeUVDerivatives = 10,
    kDebugShadersModeCheckerboard = 11,
    kDebugShadersModeUVGrid = 12,
    kDebugShadersModeDepth = 13,
    kDebugShadersModeWireframeOverlay = 14,
    kDebugShadersModeNormalDeviation = 15,
    kDebugShadersModeAmplificationID = 16,
    kDebugShadersModeInstanceID = 17,
    kDebugShadersModeQuadThread = 18,
    kDebugShadersModeSIMDGroup = 19,
    kDebugShadersModeBarycentricCoord = 20,
    kDebugShadersModeFrontFacing = 21,
    kDebugShadersModeSampleID = 22,
    kDebugShadersModePointCoord = 23,
    kDebugShadersModeDistanceToLight = 24,
    kDebugShadersModeDistanceToOrigin = 25,
    kDebugShadersModeDistanceToCamera = 26
};

struct DebugShadersUniforms {
    float4x4 modelMatrix;
    float3x3 normalMatrix;
    int debugMode;
    float3 lightPosition;
    float3 cameraPosition;
};

struct DebugShadersAmplifiedUniforms {
    float4x4 viewProjectionMatrix;
};
