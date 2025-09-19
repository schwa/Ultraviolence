import Metal
import MetalKit
import Ultraviolence
import UltraviolenceSupport

// TODO: #138 Add code to align the texture correctly in the output.

struct BillboardRenderPipeline: Element {
    let specifierA: Texture2DSpecifier
    let sliceA: Int
    let specifierB: Texture2DSpecifier
    let sliceB: Int

    let vertexShader: VertexShader
    let fragmentShader: FragmentShader
    let positions: [SIMD2<Float>]
    let textureCoordinates: [SIMD2<Float>]
    let colorTransformGraph: SimpleStitchedFunctionGraph

    // TODO: #138 Get rid of flippedY
    init(specifierA: Texture2DSpecifier, sliceA: Int = 0, specifierB: Texture2DSpecifier, sliceB: Int = 0, flippedY: Bool = false, colorTransform: VisibleFunction? = nil) throws {
        let device = _MTLCreateSystemDefaultDevice()
        #if os(iOS)
        assert(device.supportsFeatureSet(.iOS_GPUFamily4_v1)) // For argument buffers tier
        #endif
        self.specifierA = specifierA
        self.sliceA = sliceA
        self.specifierB = specifierB
        self.sliceB = sliceB
        assert(device.argumentBuffersSupport == .tier2)
        let shaderBundle = Bundle.ultraviolenceExampleShaders().orFatalError()
        let shaderLibrary = try ShaderLibrary(bundle: shaderBundle, namespace: "TextureBillboard")

        self.vertexShader = try shaderLibrary.vertex_main
        self.fragmentShader = try shaderLibrary.fragment_main
        if !flippedY {
            positions = [[-1, 1], [-1, -1], [1, 1], [1, -1]]
        }
        else {
            positions = [[-1, -1], [-1, 1], [1, -1], [1, 1]]
        }
        textureCoordinates = [[0, 1], [0, 0], [1, 1], [1, 0]]

        let colorTransform = try colorTransform ?? shaderLibrary.function(named: "colorTransformIdentity", type: VisibleFunction.self)
        colorTransformGraph = try SimpleStitchedFunctionGraph(name: "TextureBillboard::colorTransform", function: colorTransform)
    }

    var body: some Element {
        get throws {
            try RenderPipeline(vertexShader: vertexShader, fragmentShader: fragmentShader) {
                let specifierArgumentBuffer = specifierA.toTexture2DSpecifierArgmentBuffer()

                Draw { encoder in
                    encoder.setVertexBytes(positions, length: MemoryLayout<SIMD2<Float>>.stride * positions.count, index: 0)
                    encoder.setVertexBytes(textureCoordinates, length: MemoryLayout<SIMD2<Float>>.stride * textureCoordinates.count, index: 1)
                    encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: positions.count)
                }
                .parameter("specifierA", value: specifierA.toTexture2DSpecifierArgmentBuffer())
                .parameter("sliceA", value: sliceA)
                .parameter("specifierB", value: specifierB.toTexture2DSpecifierArgmentBuffer())
                .parameter("sliceB", value: sliceB)
                .parameter("transformColorParameters", value: Int32(0)) // TODO: Placeholder
                .useResource(specifierA.texture2D, usage: .read, stages: .fragment)
                .useResource(specifierA.textureCube, usage: .read, stages: .fragment)
                .useResource(specifierA.depth2D, usage: .read, stages: .fragment)
                .useResource(specifierB.texture2D, usage: .read, stages: .fragment)
                .useResource(specifierB.textureCube, usage: .read, stages: .fragment)
                .useResource(specifierB.depth2D, usage: .read, stages: .fragment)
            }
            .vertexDescriptor(try vertexShader.inferredVertexDescriptor())
            .environment(\.linkedFunctions, colorTransformGraph.linkedFunctions)
        }
    }
}

extension BillboardRenderPipeline {

    init(specifierA: Texture2DSpecifier, sliceA: Int = 0, specifierB: Texture2DSpecifier, sliceB: Int = 0, flippedY: Bool = false, colorTransformFunctionName: String) throws {
        let device = _MTLCreateSystemDefaultDevice()
        let shaderBundle = Bundle.ultraviolenceExampleShaders().orFatalError()
        let shaderLibrary = try ShaderLibrary(bundle: shaderBundle, namespace: "TextureBillboard")
        let colorTransform = try shaderLibrary.function(named: colorTransformFunctionName, type: VisibleFunction.self)

        try self.init(specifierA: specifierA, sliceA: sliceA, specifierB: specifierB, sliceB: sliceB, flippedY: flippedY, colorTransform: colorTransform)
    }

    init(specifier: Texture2DSpecifier, slice: Int = 0, flippedY: Bool = false, colorTransform: VisibleFunction? = nil) throws {
        try self.init(specifierA: specifier, sliceA: slice, specifierB: specifier, sliceB: slice, flippedY: flippedY, colorTransform: colorTransform)
    }
}

struct SimpleStitchedFunctionGraph {
    let linkedFunctions: MTLLinkedFunctions

    init(name: String, function: VisibleFunction) throws {
        let function = function.function
        let device = _MTLCreateSystemDefaultDevice()
        let inputs = [
            // TODO: Assumed 3 inputs for now. Generalize.
            MTLFunctionStitchingInputNode(argumentIndex: 0),
            MTLFunctionStitchingInputNode(argumentIndex: 1),
            MTLFunctionStitchingInputNode(argumentIndex: 2),
            MTLFunctionStitchingInputNode(argumentIndex: 3),
        ]
        let node = MTLFunctionStitchingFunctionNode(name: function.name, arguments: inputs, controlDependencies: [])
        let graph = MTLFunctionStitchingGraph(functionName: name, nodes: [node], outputNode: node, attributes: [])
        let stitchedLibraryDescriptor = MTLStitchedLibraryDescriptor(functions: [function], functionGraphs: [graph])
        let stitchedLibrary = try! device.makeLibrary(stitchedDescriptor: stitchedLibraryDescriptor)
        let stitchedFunction = try stitchedLibrary.makeFunction(name: name).orThrow(.resourceCreationFailure("Failed to create stitched function"))
        linkedFunctions = MTLLinkedFunctions(functions: [stitchedFunction])
    }
}
