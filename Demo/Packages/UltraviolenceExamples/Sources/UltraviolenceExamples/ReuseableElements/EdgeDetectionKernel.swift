import Metal
import Ultraviolence

public struct EdgeDetectionKernel: Element {
    var kernel: ComputeKernel
    var depthTexture: MTLTexture
    var colorTexture: MTLTexture

    public init(depthTexture: MTLTexture, colorTexture: MTLTexture) throws {
        kernel = try ShaderLibrary(bundle: .ultraviolenceExampleShaders()).EdgeDetectionKernel
        self.depthTexture = depthTexture
        self.colorTexture = colorTexture
    }

    public var body: some Element {
        ComputePipeline(computeKernel: kernel) {
            // TODO: #52 Compute threads per threadgroup
            ComputeDispatch(threads: .init(width: depthTexture.width, height: depthTexture.height, depth: 1), threadsPerThreadgroup: .init(width: 32, height: 32, depth: 1))
                .parameter("depthTexture", texture: depthTexture)
                .parameter("colorTexture", texture: colorTexture)
        }
    }
}
