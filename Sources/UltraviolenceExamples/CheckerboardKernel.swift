import Metal
import simd
import Ultraviolence

public struct CheckerboardKernel: Element {
    private var kernel: ComputeKernel
    private var outputTexture: MTLTexture
    private var checkerSize: SIMD2<Float>
    private var backgroundColor: SIMD4<Float>
    private var foregroundColor: SIMD4<Float>

    init(outputTexture: MTLTexture, checkerSize: SIMD2<Float>, backgroundColor: SIMD4<Float>, foregroundColor: SIMD4<Float>) throws {
        kernel = try ShaderLibrary(bundle: .module).CheckerboardKernel_float4
        self.outputTexture = outputTexture
        self.checkerSize = checkerSize
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
    }

    public var body: some Element {
        ComputePipeline(computeKernel: kernel) {
            // TODO: Compute threads per threadgroup
            ComputeDispatch(threads: .init(width: outputTexture.width, height: outputTexture.height, depth: 1), threadsPerThreadgroup: .init(width: 32, height: 32, depth: 1))
                .parameter("outputTexture", texture: outputTexture)
                .parameter("checkerSize", value: checkerSize)
                .parameter("backgroundColor", value: backgroundColor)
                .parameter("foregroundColor", value: foregroundColor)
        }
    }
}

public struct CheckerboardKernel_ushort: Element {
    private var kernel: ComputeKernel
    private var outputTexture: MTLTexture
    private var checkerSize: SIMD2<Float>
    private var backgroundColor: UInt16
    private var foregroundColor: UInt16

    init(outputTexture: MTLTexture, checkerSize: SIMD2<Float>, backgroundColor: UInt16, foregroundColor: UInt16) throws {
        kernel = try ShaderLibrary(bundle: .module).CheckerboardKernel_ushort
        self.outputTexture = outputTexture
        self.checkerSize = checkerSize
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
    }

    public var body: some Element {
        ComputePipeline(computeKernel: kernel) {
            // TODO: Compute threads per threadgroup
            ComputeDispatch(threads: .init(width: outputTexture.width, height: outputTexture.height, depth: 1), threadsPerThreadgroup: .init(width: 32, height: 32, depth: 1))
                .parameter("outputTexture", texture: outputTexture)
                .parameter("checkerSize", value: checkerSize)
                .parameter("backgroundColor", value: backgroundColor)
                .parameter("foregroundColor", value: foregroundColor)
        }
    }
}

extension CheckerboardKernel: Example {
    @MainActor
    public static func runExample() throws -> ExampleResult {
        let device = MTLCreateSystemDefaultDevice()!
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: 512, height: 512, mipmapped: false)
        textureDescriptor.usage = [.shaderWrite, .shaderRead]
        let texture = device.makeTexture(descriptor: textureDescriptor)!
        let pass = try ComputePass {
            try CheckerboardKernel(outputTexture: texture, checkerSize: [32, 32], backgroundColor: [0, 0, 0, 1], foregroundColor: [1, 1, 1, 1])
        }
        try pass.compute()
        return .texture(texture)
    }
}
