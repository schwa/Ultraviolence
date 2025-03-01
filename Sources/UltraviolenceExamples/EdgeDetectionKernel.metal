#import <metal_stdlib>
#import <metal_logging>

using namespace metal;

kernel void EdgeDetectionKernel(
    texture2d<float, access::read> depthTexture [[texture(0)]],
    texture2d<float, access::write> colorTexture [[texture(1)]],
    uint2 gid [[thread_position_in_grid]]
) {
    uint width = depthTexture.get_width();
    uint height = depthTexture.get_height();

    // Read current pixel and four neighbors
    float pixel00 = depthTexture.read(gid).r;

    //os_log_default.log("(%d, %d): %f, %f, %f, %f", gid.x, gid.y, pixel.x, pixel.y, pixel.z, pixel.w);

    float pixelLeft = (gid.x > 0) ? depthTexture.read(gid + uint2(-1, 0)).r : pixel00;
    float pixelRight = (gid.x + 1 < width) ? depthTexture.read(gid + uint2(1, 0)).r : pixel00;
    float pixelUp = (gid.y > 0) ? depthTexture.read(gid + uint2(0, -1)).r : pixel00;
    float pixelDown = (gid.y + 1 < height) ? depthTexture.read(gid + uint2(0, 1)).r : pixel00;

    // Compute gradients using central differences
    float dx = (pixelRight - pixelLeft) * 0.5;
    float dy = (pixelDown - pixelUp) * 0.5;

    float gradient = sqrt(dx * dx + dy * dy);

    // Edge detection logic
    if (gradient * 800 > 1) {
        colorTexture.write(float4(1.0, 1.0, 1.0, 1.0), gid); // Draw edge in white
    }
}
