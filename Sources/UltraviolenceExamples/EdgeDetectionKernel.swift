import Ultraviolence

public struct EdgeDetectionKernel: RenderPass {
    let source = """
    #import <metal_stdlib>
    #import <metal_logging>

    using namespace metal;

    kernel void EdgeDetectionKernel(
        texture2d<float, access::read> depth [[texture(0)]],
        texture2d<float, access::read_write> color [[texture(1)]],
        uint2 gid [[thread_position_in_grid]]
    ) {

        uint width = depth.get_width();
        uint height = depth.get_height();

        // Read current pixel and four neighbors
        float pixel00 = depth.read(gid).r;
        float4 pixel = depth.read(gid);

        //os_log_default.log("(%d, %d): %f, %f, %f, %f", gid.x, gid.y, pixel.x, pixel.y, pixel.z, pixel.w);

        float pixelLeft = (gid.x > 0) ? depth.read(gid + uint2(-1, 0)).r : pixel00;
        float pixelRight = (gid.x + 1 < width) ? depth.read(gid + uint2(1, 0)).r : pixel00;
        float pixelUp = (gid.y > 0) ? depth.read(gid + uint2(0, -1)).r : pixel00;
        float pixelDown = (gid.y + 1 < height) ? depth.read(gid + uint2(0, 1)).r : pixel00;

        // Compute gradients using central differences
        float dx = (pixelRight - pixelLeft) * 0.5;
        float dy = (pixelDown - pixelUp) * 0.5;

        float gradient = sqrt(dx * dx + dy * dy);

        // Read current color
        float4 currentColor = color.read(gid);

        //        os_log_default.log("%f", gradient);

        // Edge detection logic
        if (gradient * 800 > 1) {
            color.write(float4(1.0, 1.0, 1.0, 1.0), gid); // Draw edge in white
        } else {
            color.write(currentColor, gid); // Retain the existing color
        }
    }
    """

    public init() {
        // This line intentionally left blank.
    }

    public var body: some RenderPass {
        get throws {
            try ComputeShader("EdgeDetectionKernel", source: source)
        }
    }
}
