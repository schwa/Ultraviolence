import Metal
import simd
import Ultraviolence
import UltraviolenceSupport

public struct CheckerboardKernel: Element {
    private var kernel: ComputeKernel
    private var outputTexture: MTLTexture
    private var checkerSize: SIMD2<Float>
    private var foregroundColor: SIMD4<Float>

    public init(outputTexture: MTLTexture, checkerSize: SIMD2<Float>, foregroundColor: SIMD4<Float>) throws {
        kernel = try ShaderLibrary(bundle: .ultraviolenceExampleShaders(), namespace: "Checkerboard").CheckerboardKernel_float4
        self.outputTexture = outputTexture
        self.checkerSize = checkerSize
        self.foregroundColor = foregroundColor
    }

    public var body: some Element {
        get throws {
            try ComputePipeline(computeKernel: kernel) {
                // TODO: #52 Compute threads per threadgroup
                try ComputeDispatch(threadsPerGrid: .init(width: outputTexture.width, height: outputTexture.height, depth: 1), threadsPerThreadgroup: .init(width: 32, height: 32, depth: 1))
                    .parameter("outputTexture", texture: outputTexture)
                    .parameter("checkerSize", value: checkerSize)
                    .parameter("foregroundColor", value: foregroundColor)
            }
        }
    }
}

public struct CheckerboardKernel_ushort: Element {
    private var kernel: ComputeKernel
    private var outputTexture: MTLTexture
    private var checkerSize: SIMD2<Float>
    private var foregroundColor: UInt16

    public init(outputTexture: MTLTexture, checkerSize: SIMD2<Float>, foregroundColor: UInt16) throws {
        kernel = try ShaderLibrary(bundle: .ultraviolenceExampleShaders(), namespace: "Checkerboard").CheckerboardKernel_ushort
        self.outputTexture = outputTexture
        self.checkerSize = checkerSize
        self.foregroundColor = foregroundColor
    }

    public var body: some Element {
        get throws {
            try ComputePipeline(computeKernel: kernel) {
                // TODO: #52 Compute threads per threadgroup
                try ComputeDispatch(threadsPerGrid: .init(width: outputTexture.width, height: outputTexture.height, depth: 1), threadsPerThreadgroup: .init(width: 32, height: 32, depth: 1))
                    .parameter("outputTexture", texture: outputTexture)
                    .parameter("checkerSize", value: checkerSize)
                    .parameter("foregroundColor", value: foregroundColor)
            }
        }
    }
}

extension CheckerboardKernel: Example {
    @MainActor
    public static func runExample() throws -> ExampleResult {
        let device = _MTLCreateSystemDefaultDevice()
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: 512, height: 512, mipmapped: false)
        textureDescriptor.usage = [.shaderWrite, .shaderRead]
        let texture = try device.makeTexture(descriptor: textureDescriptor, repeating: UInt32(0xFF000000))
        let pass = try ComputePass {
            try CheckerboardKernel(outputTexture: texture, checkerSize: [32, 32], foregroundColor: [1, 1, 1, 1])
        }
        try pass.run()
        return .texture(texture)
    }
}
