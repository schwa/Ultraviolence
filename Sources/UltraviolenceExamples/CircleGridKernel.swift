import Metal
import simd
import Ultraviolence
internal import UltraviolenceSupport

public struct CircleGridKernel: Element {
    private var kernel: ComputeKernel
    private var outputTexture: MTLTexture
    private var spacing: SIMD2<Float>
    private var radius: Float
    private var foregroundColor: SIMD4<Float>

    init(outputTexture: MTLTexture, spacing: SIMD2<Float>, radius: Float, foregroundColor: SIMD4<Float>) throws {
        kernel = try ShaderLibrary(bundle: .module).CircleGridKernel_float4
        self.outputTexture = outputTexture
        self.spacing = spacing
        self.radius = radius
        self.foregroundColor = foregroundColor
    }

    public var body: some Element {
        ComputePipeline(computeKernel: kernel) {
            // TODO: Compute threads per threadgroup
            ComputeDispatch(threads: .init(width: outputTexture.width, height: outputTexture.height, depth: 1), threadsPerThreadgroup: .init(width: 32, height: 32, depth: 1))
                .parameter("outputTexture", texture: outputTexture)
                .parameter("spacing", value: spacing)
                .parameter("radius", value: radius)
                .parameter("foregroundColor", value: foregroundColor)
        }
    }
}

extension CircleGridKernel: Example {
    @MainActor
    public static func runExample() throws -> ExampleResult {
        let device = _MTLCreateSystemDefaultDevice()
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: 512, height: 512, mipmapped: false)
        textureDescriptor.usage = [.shaderWrite, .shaderRead]
        let texture = try device.makeTexture(descriptor: textureDescriptor, value: UInt32(0xFF000000))
        let pass = try ComputePass {
            try CircleGridKernel(outputTexture: texture, spacing: [32, 32], radius: 16, foregroundColor: [1, 1, 1, 1])
        }
        try pass.run()
        return .texture(texture)
    }
}
