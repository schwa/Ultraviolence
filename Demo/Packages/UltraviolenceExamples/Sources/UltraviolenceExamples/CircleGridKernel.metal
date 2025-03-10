#import <metal_stdlib>
#import <metal_logging>

using namespace metal;

uint2 gid [[thread_position_in_grid]];

kernel void CircleGridKernel_float4(
    texture2d<float, access::read_write> outputTexture [[texture(0)]],
    constant float2 &spacing [[buffer(0)]],
    constant float &radius [[buffer(1)]],
    constant float4 &foregroundColor [[buffer(2)]]
) {
    if (gid.x >= outputTexture.get_width() || gid.y >= outputTexture.get_height()) {
        return;
    }
    const float2 pixelCoord = float2(gid);
    const float2 gridCoord = round(pixelCoord / spacing) * spacing;
    const float distance = length(pixelCoord - gridCoord);
    if (distance <= radius) {
        outputTexture.write(foregroundColor, gid);
    }
}
