#pragma once

#import "Support.h"

struct BoxInstance {
    float3 min;
    float3 max;
    float4 color;
};

struct BoxesUniforms {
    float4x4 mvpMatrix;
    float3 nudge;
};