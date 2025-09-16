import Metal
import Ultraviolence
import UltraviolenceSupport

/// Pipeline that blends thermal effect with video based on heat intensity
public struct ThermalVideoBlendPipeline: Element {
    let thermalTexture: MTLTexture  // Colored thermal effect
    let videoTexture: MTLTexture?   // Video frame (optional)
    let heatTexture: MTLTexture     // Raw heat values
    let outputTexture: MTLTexture   // Final blended output
    let videoBlendAmount: Float
    
    public init(
        thermalTexture: MTLTexture,
        videoTexture: MTLTexture? = nil,
        heatTexture: MTLTexture,
        outputTexture: MTLTexture,
        videoBlendAmount: Float = 0.7
    ) {
        self.thermalTexture = thermalTexture
        self.videoTexture = videoTexture
        self.heatTexture = heatTexture
        self.outputTexture = outputTexture
        self.videoBlendAmount = videoBlendAmount
    }
    
    public var body: some Element {
        get throws {
            let shaderLibrary = try ShaderLibrary(
                bundle: .ultraviolenceExampleShaders().orFatalError(),
                namespace: "ThermalVideoBlend"
            )
            
            if let videoTexture = videoTexture {
                // Use full blending kernel when video is available
                try ComputePipeline(
                    computeKernel: try shaderLibrary.blendThermalWithVideo
                ) {
                    try ComputeDispatch(
                        threadsPerGrid: MTLSize(
                            width: outputTexture.width,
                            height: outputTexture.height,
                            depth: 1
                        ),
                        threadsPerThreadgroup: MTLSize(width: 16, height: 16, depth: 1)
                    )
                    .parameter("thermalTexture", texture: thermalTexture)
                    .parameter("videoTexture", texture: videoTexture)
                    .parameter("heatTexture", texture: heatTexture)
                    .parameter("outputTexture", texture: outputTexture)
                    .parameter("videoBlendAmount", value: videoBlendAmount)
                }
            } else {
                // Passthrough when no video
                try ComputePipeline(
                    computeKernel: try shaderLibrary.passthroughThermal
                ) {
                    try ComputeDispatch(
                        threadsPerGrid: MTLSize(
                            width: outputTexture.width,
                            height: outputTexture.height,
                            depth: 1
                        ),
                        threadsPerThreadgroup: MTLSize(width: 16, height: 16, depth: 1)
                    )
                    .parameter("thermalTexture", texture: thermalTexture)
                    .parameter("outputTexture", texture: outputTexture)
                }
            }
        }
    }
}