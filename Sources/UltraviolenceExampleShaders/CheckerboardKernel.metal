#import <metal_logging>
#import <metal_stdlib>

using namespace metal;

namespace Checkerboard {

    uint2 gid [[thread_position_in_grid]];

    bool checkerboard(float2 coord, float2 size) {
        const float2 checkerCoord = floor(coord / size);
        const float checkerValue = fmod(checkerCoord.x + checkerCoord.y, 2.0);
        return checkerValue != 0.0;
    }

    kernel void CheckerboardKernel_float4(
        texture2d<float, access::read_write> outputTexture [[texture(0)]],
        constant float2 &checkerSize [[buffer(0)]],
        constant float4 &foregroundColor [[buffer(2)]]
    ) {
        if (checkerboard(float2(gid), checkerSize)) {
            outputTexture.write(foregroundColor, gid);
        }
    }

    kernel void CheckerboardKernel_ushort(
        texture2d<ushort, access::read_write> outputTexture [[texture(0)]],
        constant float2 &checkerSize [[buffer(0)]],
        constant ushort &foregroundColor [[buffer(2)]]
    ) {
        if (checkerboard(float2(gid), checkerSize)) {
            outputTexture.write(foregroundColor, gid);
        }
    }

} // namespace Checkerboard
