import Ultraviolence

public struct EdgeDetectionKernel: RenderPass {
    let source = """
    #include <metal_stdlib>
    using namespace metal;

    kernel void EdgeDetectionKernel(
        texture2d<float, access::read> inTexture [[texture(0)]],
        texture2d<float, access::write> outTexture [[texture(1)]],
        uint2 gid [[thread_position_in_grid]]
    ) {
        uint width = inTexture.get_width();
        uint height = inTexture.get_height();

        // Bounds checking for neighboring pixels
        float3 pixel00 = inTexture.read(gid).rgb;
        float3 pixel01 = (gid.x + 1 < width) ? inTexture.read(gid + uint2(1, 0)).rgb : pixel00;
        float3 pixel10 = (gid.y + 1 < height) ? inTexture.read(gid + uint2(0, 1)).rgb : pixel00;

        float3 dx = pixel01 - pixel00;
        float3 dy = pixel10 - pixel00;

        float3 gradient = sqrt(dx * dx + dy * dy);

        outTexture.write(float4(gradient, 1.0), gid);
    }
    """

    public init() {
        // This line intentionally left blank.
    }

    public var body: some RenderPass {
        try! ComputeShader("EdgeDetectionKernel", source: source)
    }
}
