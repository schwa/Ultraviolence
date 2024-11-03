import Ultraviolence

public struct EdgeDetectionKernel: RenderPass {
    public typealias Body = Never

    let source = """
    #include <metal_stdlib>
    using namespace metal;
        
    uint2 gid [[thread_position_in_grid]]

    [[kernel]] void EdgeDetectionKernel(
        texture2d<float, access::read> inTexture [[texture(0)]],
        texture2d<float, access::write> outTexture [[texture(1)]],
    ) {
        float3 pixel00 = inTexture.read(gid).rgb;
        float3 pixel01 = inTexture.read(gid + uint2(1, 0)).rgb;
        float3 pixel10 = inTexture.read(gid + uint2(0, 1)).rgb;
        float3 pixel11 = inTexture.read(gid + uint2(1, 1)).rgb;
            
        float3 dx = pixel01 - pixel00;
        float3 dy = pixel10 - pixel00;
        
        float3 gradient = sqrt(dx * dx + dy * dy);
        
        outTexture.write(float4(gradient, 1.0), gid);
    }
    
    """

    public init() {
    }

    public func visit(_ visitor: inout Visitor) throws {
        try ComputeShader("EdgeDetectionKernel", source: source)
    }
}
