import Metal
import Ultraviolence
import UltraviolenceSupport

public struct ColorAdjustComputePipeline <T>: Element {
    let inputSpecifier: Texture2DSpecifier
    let inputParameters: T
    let outputTexture: MTLTexture
    var kernel: ComputeKernel

    init(inputSpecifier: Texture2DSpecifier, inputParameters: T, outputTexture: MTLTexture) {
        self.inputSpecifier = inputSpecifier
        self.inputParameters = inputParameters
        self.outputTexture = outputTexture
        let shaderLibrary = try! ShaderLibrary(bundle: .ultraviolenceExampleShaders().orFatalError(), namespace: "ColorAdjust")
        self.kernel = try! shaderLibrary.colorAdjust
    }

    public var body: some Element {
        get throws {
            try ComputePipeline(
                computeKernel: kernel
            ) {
                try ComputeDispatch(threadsPerGrid: [outputTexture.width, outputTexture.height, 1], threadsPerThreadgroup: [16, 16, 1])
                    // TODO: #280 Maybe a .argumentBuffer() is a better solution
                    .parameter("inputSpecifier", value: inputSpecifier.toTexture2DSpecifierArgmentBuffer())
                    .useComputeResource(inputSpecifier.texture2D, usage: .read)
                    .useComputeResource(inputSpecifier.textureCube, usage: .read)
                    .useComputeResource(inputSpecifier.depth2D, usage: .read)
                    .parameter("inputParameters", value: inputParameters)
                    .parameter("outputTexture", texture: outputTexture)
            }
        }
    }
}
