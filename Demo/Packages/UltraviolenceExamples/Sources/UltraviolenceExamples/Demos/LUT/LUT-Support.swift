import Metal
import Ultraviolence

/// Create a 3D LUT texture from a 2D LUT texture. The 2D LUT texture is expected to be a 512x512 texture and the output 3D LUT texture will be 64x64x64.
@MainActor
func create3DLUT(device: MTLDevice, from lut2DTexture: MTLTexture) throws -> MTLTexture? {
    let source = """
    #include <metal_stdlib>
    using namespace metal;

    kernel void lut2DTo3D(texture2d<float, access::read> lut2D [[texture(0)]], texture3d<float, access::write> lut3D [[texture(1)]], uint3 gid [[thread_position_in_grid]]) {
        const uint lutSize = 64;
        if (gid.x >= lutSize || gid.y >= lutSize || gid.z >= lutSize) return;
        uint tilesPerRow = 8;
        uint tileX = gid.z % tilesPerRow;
        uint tileY = gid.z / tilesPerRow;
        uint x = tileX * lutSize + gid.x;
        uint y = tileY * lutSize + gid.y;
        float4 color = lut2D.read(uint2(x, y));
        lut3D.write(color, gid);
    }
    """
    let size = MTLSize(width: 64, height: 64, depth: 64)
    let descriptor = MTLTextureDescriptor()
    descriptor.textureType = .type3D
    descriptor.pixelFormat = lut2DTexture.pixelFormat
    descriptor.width = size.width
    descriptor.height = size.height
    descriptor.depth = size.depth
    descriptor.usage = [.shaderRead, .shaderWrite]
    let texture3D = device.makeTexture(descriptor: descriptor)!
    let pass = try ComputePass {
        try ComputePipeline(computeKernel: .init(source: source)) {
            let threadsPerThreadgroup = MTLSize(width: 16, height: 8, depth: 8)
            // TODO: #52 Compute threads per threadgroup
            ComputeDispatch(threads: size, threadsPerThreadgroup: threadsPerThreadgroup)
                .parameter("lut2D", texture: lut2DTexture)
                .parameter("lut3D", texture: texture3D)
        }
    }
    try pass.run()
    return texture3D
}
