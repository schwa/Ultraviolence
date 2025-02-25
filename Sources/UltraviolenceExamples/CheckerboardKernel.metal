#import <metal_stdlib>
#import <metal_logging>

using namespace metal;

uint2 gid [[thread_position_in_grid]];

kernel void CheckerboardKernel(
    texture2d<float, access::read_write> outputTexture [[texture(0)]],
    constant float2 &checkerSize [[buffer(0)]],
    constant float4 &backgroundColor[[buffer(1)]],
    constant float4 &foregroundColor[[buffer(2)]]
) {
    float2 checkerCoord = floor(float2(gid) / checkerSize);
    float checkerValue = fmod(checkerCoord.x + checkerCoord.y, 2.0);
    float4 color = (checkerValue == 0.0) ? backgroundColor : foregroundColor;
    outputTexture.write(color, gid);
}
