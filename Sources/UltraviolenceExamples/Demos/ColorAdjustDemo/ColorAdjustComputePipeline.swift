import Metal
import Ultraviolence
import UltraviolenceSupport

public struct ColorAdjustComputePipeline <T>: Element {
    let inputSpecifier: ColorSource
    let inputParameters: T
    let outputTexture: MTLTexture
    let kernel: ComputeKernel
    let mapTextureCoordinateGraph: SimpleStitchedFunctionGraph
    let colorAdjustGraph: SimpleStitchedFunctionGraph

    // TODO: the two VisibleFunction parameters should be documented well.
    init(inputSpecifier: ColorSource, inputParameters: T, outputTexture: MTLTexture, mapTextureCoordinateFunction: VisibleFunction? = nil, colorAdjustFunction: VisibleFunction) throws {
        self.inputSpecifier = inputSpecifier
        self.inputParameters = inputParameters
        self.outputTexture = outputTexture
        let shaderLibrary = try ShaderLibrary(bundle: .ultraviolenceExampleShaders().orFatalError(), namespace: "ColorAdjust")
        self.kernel = try shaderLibrary.colorAdjust

        let mapTextureCoordinateFunction = try mapTextureCoordinateFunction ?? shaderLibrary.function(named: "mapTextureCoordinateIdentity", type: VisibleFunction.self)
        mapTextureCoordinateGraph = try! SimpleStitchedFunctionGraph(name: "ColorAdjust::mapTextureCoordinateFunction", function: mapTextureCoordinateFunction, inputs: 2)
        colorAdjustGraph = try! SimpleStitchedFunctionGraph(name: "ColorAdjust::colorAdjustFunction", function: colorAdjustFunction, inputs: 3)
    }

    public var body: some Element {
        get throws {
            try ComputePipeline(computeKernel: kernel) {
                try ComputeDispatch(threadsPerGrid: [outputTexture.width, outputTexture.height, 1], threadsPerThreadgroup: [16, 16, 1])
                    // TODO: #280 Maybe a .argumentBuffer() is a better solution
                    .parameter("inputSpecifier", value: inputSpecifier.toArgumentBuffer())
                    .parameter("inputParameters", value: inputParameters)
                    .parameter("outputTexture", texture: outputTexture)
                    .useComputeResource(inputSpecifier.texture2D, usage: .read)
                    .useComputeResource(inputSpecifier.textureCube, usage: .read)
                    .useComputeResource(inputSpecifier.depth2D, usage: .read)
            }
            .environment(\.linkedFunctions, MTLLinkedFunctions(functions: mapTextureCoordinateGraph.stitchedFunctions + colorAdjustGraph.stitchedFunctions))
        }
    }
}

extension ColorAdjustComputePipeline where T == Float {
    static func gammaAdjustPipeline(inputSpecifier: ColorSource, inputParameters: Float, outputTexture: MTLTexture) -> Self {
        let shaderLibrary = try! ShaderLibrary(bundle: .ultraviolenceExampleShaders().orFatalError(), namespace: "ColorAdjust")
        let colorAdjustFunction = try! shaderLibrary.function(named: "gamma", type: VisibleFunction.self)
        return try! ColorAdjustComputePipeline(inputSpecifier: inputSpecifier, inputParameters: inputParameters, outputTexture: outputTexture, colorAdjustFunction: colorAdjustFunction)
    }
}
