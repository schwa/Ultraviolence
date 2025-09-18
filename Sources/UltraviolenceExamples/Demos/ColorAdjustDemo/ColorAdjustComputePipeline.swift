import Metal
import Ultraviolence
import UltraviolenceSupport

public struct ColorAdjustComputePipeline <T>: Element {
    let inputSpecifier: Texture2DSpecifier
    let inputParameters: T
    let outputTexture: MTLTexture
    let kernel: ComputeKernel
    let linkedFunctions: MTLLinkedFunctions

    init(inputSpecifier: Texture2DSpecifier, inputParameters: T, outputTexture: MTLTexture, colorAdjustFunction: MTLFunction) {
        let device = _MTLCreateSystemDefaultDevice()

        self.inputSpecifier = inputSpecifier
        self.inputParameters = inputParameters
        self.outputTexture = outputTexture
        let shaderLibrary = try! ShaderLibrary(bundle: .ultraviolenceExampleShaders().orFatalError(), namespace: "ColorAdjust")
        self.kernel = try! shaderLibrary.colorAdjust


        // TODO: #283 Use Ultraviolence's normal shader loading capabilities
        // TODO: #284 Use proper Metal function loading - this one requires all functions to be named the same.
        // TODO: #285 Terrible example of stitchable functions.

        let inputs = [
            MTLFunctionStitchingInputNode(argumentIndex: 0),
            MTLFunctionStitchingInputNode(argumentIndex: 1),
            MTLFunctionStitchingInputNode(argumentIndex: 2),
        ]
        let colorAdjustNode = MTLFunctionStitchingFunctionNode(name: colorAdjustFunction.name, arguments: inputs, controlDependencies: [])
        let colorAdjustGraph = MTLFunctionStitchingGraph(functionName: "colorAdjustFunction", nodes: [colorAdjustNode], outputNode: colorAdjustNode, attributes: [])
        let stitchedLibraryDescriptor = MTLStitchedLibraryDescriptor(functions: [colorAdjustFunction], functionGraphs: [colorAdjustGraph])
        let stitchedLibrary = try! device.makeLibrary(stitchedDescriptor: stitchedLibraryDescriptor)
        let stitchedFunction = stitchedLibrary.makeFunction(name: "colorAdjustFunction")!
        self.linkedFunctions = MTLLinkedFunctions(functions: [stitchedFunction])
    }

    public var body: some Element {
        get throws {
            try ComputePipeline(computeKernel: kernel) {
                try ComputeDispatch(threadsPerGrid: [outputTexture.width, outputTexture.height, 1], threadsPerThreadgroup: [16, 16, 1])
                    // TODO: #280 Maybe a .argumentBuffer() is a better solution
                    .parameter("inputSpecifier", value: inputSpecifier.toTexture2DSpecifierArgmentBuffer())
                    .useComputeResource(inputSpecifier.texture2D, usage: .read)
                    .useComputeResource(inputSpecifier.textureCube, usage: .read)
                    .useComputeResource(inputSpecifier.depth2D, usage: .read)
                    .parameter("inputParameters", value: inputParameters)
                    .parameter("outputTexture", texture: outputTexture)
            }
            .environment(\.linkedFunctions, linkedFunctions)

        }
    }
}

// TODO: Move
extension MTLLinkedFunctions {
    convenience init(functions: [MTLFunction]) {
        self.init()
        self.functions = functions
    }
}

extension MTLStitchedLibraryDescriptor {
    convenience init(functions: [MTLFunction], functionGraphs: [MTLFunctionStitchingGraph]) {
        self.init()
        self.functions = functions
        self.functionGraphs = functionGraphs
    }
}
