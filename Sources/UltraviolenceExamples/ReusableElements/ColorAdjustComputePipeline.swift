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
        // TODO: This will be compiled every time!
        let shaderLibrary = try! ShaderLibrary(bundle: .ultraviolenceExampleShaders().orFatalError(), namespace: "ColorAdjust")
        self.kernel = try! shaderLibrary.colorAdjust
    }

    public var body: some Element {
        get throws {
            try ComputePipeline(
                computeKernel: kernel
            ) {
                try ComputeDispatch(threadsPerGrid: [outputTexture.width, outputTexture.height, 1], threadsPerThreadgroup: [16, 16, 1])
                // TODO: mayebe a .argumentBuffer() is a better solution [FILE THIS]
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

// TODO: Move
extension MTLSize: @retroactive ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Int...) {
        switch elements.count {
        case 0:
            self = .init(width: 0, height: 0, depth: 0)
        case 1:
            self = .init(width: elements[0], height: 0, depth: 0)
        case 2:
            self = .init(width: elements[0], height: elements[1], depth: 0)
        case 3:
            self = .init(width: elements[0], height: elements[1], depth: elements[2])
        default:
            fatalError()
        }
    }
}
