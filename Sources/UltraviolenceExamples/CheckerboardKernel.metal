#import <metal_stdlib>
#import <metal_logging>

using namespace metal;

uint2 gid [[thread_position_in_grid]];

kernel void CheckerboardKernel_float4(
    texture2d<float, access::read_write> outputTexture [[texture(0)]],
    constant float2 &checkerSize [[buffer(0)]],
    constant float4 &foregroundColor[[buffer(2)]]
) {
    const float2 checkerCoord = floor(float2(gid) / checkerSize);
    const float checkerValue = fmod(checkerCoord.x + checkerCoord.y, 2.0);
    if (checkerValue != 0.0) {
        outputTexture.write(foregroundColor, gid);
    }
}

kernel void CheckerboardKernel_ushort(
    texture2d<ushort, access::read_write> outputTexture [[texture(0)]],
    constant float2 &checkerSize [[buffer(0)]],
    constant ushort &foregroundColor[[buffer(2)]]
) {
    const float2 checkerCoord = floor(float2(gid) / checkerSize);
    const float checkerValue = fmod(checkerCoord.x + checkerCoord.y, 2.0);
    if (checkerValue != 0.0) {
        outputTexture.write(foregroundColor, gid);
    }
}
