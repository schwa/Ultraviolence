#import <metal_stdlib>
#import <metal_logging>

using namespace metal;

uint2 gid [[thread_position_in_grid]];

kernel void CircleGridKernel_float4(
    texture2d<float, access::read_write> outputTexture [[texture(0)]],
    constant float2 &spacing [[buffer(0)]],
    constant float2 &radius [[buffer(1)]],
    constant float4 &backgroundColor[[buffer(2)]],
    constant float4 &foregroundColor[[buffer(3)]]
) {
    const float2 gridCoord = float2(gid) * spacing;
    const float2 gridCenter = gridCoord + spacing * 0.5;
    const float distance = length(gridCenter - float2(0.5));
    const auto color = (distance < radius.x) ? foregroundColor : backgroundColor;
    outputTexture.write(color, gid);
}
