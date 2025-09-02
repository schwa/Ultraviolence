import Metal
import Ultraviolence

/// A compute pipeline that applies a 3D LUT to an image.
struct LUTComputePipeline: Element {
    let inputTexture: MTLTexture
    let lutTexture: MTLTexture
    let blend: Float
    let outputTexture: MTLTexture
    let kernel: ComputeKernel

    /// Creates a new compute pipeline that applies a 3D LUT to an image.
    /// - Parameters:
    ///  - inputTexture: The input texture.
    ///  - lutTexture: The 3D LUT texture.
    ///  - blend: The blend factor.
    ///  - outputTexture: The output texture. Ths should be a 2D texture of the same dimensions as the input texture
    init(inputTexture: MTLTexture, lutTexture: MTLTexture, blend: Float, outputTexture: MTLTexture) throws {
        precondition(lutTexture.textureType == .type3D, "LUT texture must be a 3D texture")
        precondition(inputTexture.width == outputTexture.width && inputTexture.height == outputTexture.height, "Input and output textures must have the same dimensions")

        self.inputTexture = inputTexture
        self.lutTexture = lutTexture
        self.blend = blend
        self.outputTexture = outputTexture
        kernel = try Ultraviolence.ShaderLibrary(bundle: .ultraviolenceExampleShaders()).applyLUT
    }

    var body: some Element {
        ComputePipeline(computeKernel: kernel) {
            let threads = MTLSize(width: inputTexture.width, height: inputTexture.height, depth: 1)
            let threadsPerThreadgroup = MTLSize(width: 32, height: 32, depth: 1)
            // TODO: #52 Compute threads per threadgroup
            ComputeDispatch(threads: threads, threadsPerThreadgroup: threadsPerThreadgroup)
                .parameter("inputTexture", texture: inputTexture)
                .parameter("lutTexture", texture: lutTexture)
                .parameter("outputTexture", texture: outputTexture)
                .parameter("blend", value: blend)
        }
    }
}
