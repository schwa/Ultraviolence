#import <simd/simd.h>

// Metal debugger format: float3 position, uint32_t padding, half2 u1, half2 u2, half2 u3, uchar4 color

struct GPUSplat {
    simd_float3 position; // 12
    // padding // 4
    simd_half2 u1;     // 4
    simd_half2 u2;     // 4
    simd_half2 u3;     // 4
    simd_uchar4 color; // 4
};

// Metal debugger format: uint32_t Index, float distance
struct IndexedDistance {
    unsigned int index;
    float distanceToCamera;
};
