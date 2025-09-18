import Metal
import simd
import Ultraviolence
import UltraviolenceSupport

public struct CircleGridKernel: Element {
    private var kernel: ComputeKernel
    private var outputTexture: MTLTexture
    private var spacing: SIMD2<Float>
    private var radius: Float
    private var foregroundColor: SIMD4<Float>

    public init(outputTexture: MTLTexture, spacing: SIMD2<Float>, radius: Float, foregroundColor: SIMD4<Float>) throws {
        kernel = try ShaderLibrary(bundle: .ultraviolenceExampleShaders()).CircleGridKernel_float4
        self.outputTexture = outputTexture
        self.spacing = spacing
        self.radius = radius
        self.foregroundColor = foregroundColor
    }

    public var body: some Element {
        get throws {
            try ComputePipeline(computeKernel: kernel) {
                // TODO: #52 Compute threads per threadgroup
                try ComputeDispatch(threadsPerGrid: .init(width: outputTexture.width, height: outputTexture.height, depth: 1), threadsPerThreadgroup: .init(width: 32, height: 32, depth: 1))
                    .parameter("outputTexture", texture: outputTexture)
                    .parameter("spacing", value: spacing)
                    .parameter("radius", value: radius)
                    .parameter("foregroundColor", value: foregroundColor)
            }
        }
    }
}
