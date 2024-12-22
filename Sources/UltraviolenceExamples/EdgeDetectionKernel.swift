import Metal
import Ultraviolence

public struct EdgeDetectionKernel: Element {
    let source = """
    #import <metal_stdlib>
    #import <metal_logging>

    using namespace metal;

    kernel void EdgeDetectionKernel(
        texture2d<float, access::read> depthTexture [[texture(0)]],
        texture2d<float, access::read_write> colorTexture [[texture(1)]],
        uint2 gid [[thread_position_in_grid]]
    ) {

        uint width = depthTexture.get_width();
        uint height = depthTexture.get_height();

        // Read current pixel and four neighbors
        float pixel00 = depthTexture.read(gid).r;
        float4 pixel = depthTexture.read(gid);

        //os_log_default.log("(%d, %d): %f, %f, %f, %f", gid.x, gid.y, pixel.x, pixel.y, pixel.z, pixel.w);

        float pixelLeft = (gid.x > 0) ? depthTexture.read(gid + uint2(-1, 0)).r : pixel00;
        float pixelRight = (gid.x + 1 < width) ? depthTexture.read(gid + uint2(1, 0)).r : pixel00;
        float pixelUp = (gid.y > 0) ? depthTexture.read(gid + uint2(0, -1)).r : pixel00;
        float pixelDown = (gid.y + 1 < height) ? depthTexture.read(gid + uint2(0, 1)).r : pixel00;

        // Compute gradients using central differences
        float dx = (pixelRight - pixelLeft) * 0.5;
        float dy = (pixelDown - pixelUp) * 0.5;

        float gradient = sqrt(dx * dx + dy * dy);

        // Read current color
        float4 currentColor = colorTexture.read(gid);

        // Edge detection logic
        if (gradient * 800 > 1) {
            colorTexture.write(float4(1.0, 1.0, 1.0, 1.0), gid); // Draw edge in white
        } else {
            colorTexture.write(currentColor, gid); // Retain the existing color
        }
    }
    """

    var kernel: ComputeKernel
    var depthTexture: MTLTexture
    var colorTexture: MTLTexture

    public init(depthTexture: MTLTexture, colorTexture: MTLTexture) throws {
        kernel = try ComputeKernel(source: source)
        self.depthTexture = depthTexture
        self.colorTexture = colorTexture
    }

    public var body: some Element {
        ComputePipeline(computeKernel: kernel) {
            // TODO: Compute threads per threadgroup
            ComputeDispatch(threads: .init(width: depthTexture.width, height: depthTexture.height, depth: 1), threadsPerThreadgroup: .init(width: 32, height: 32, depth: 1))
            .parameter("depthTexture", texture: depthTexture)
            .parameter("colorTexture", texture: colorTexture)
        }
    }
}
