import Metal
import MetalKit
import Ultraviolence
import UltraviolenceSupport

struct Quad {
    var min: SIMD2<Float>
    var max: SIMD2<Float>
}

extension Quad {
    var minXMinY: SIMD2<Float> {
        SIMD2<Float>(min.x, min.y)
    }
    var minXMaxY: SIMD2<Float> {
        SIMD2<Float>(min.x, max.y)
    }
    var maxXMinY: SIMD2<Float> {
        SIMD2<Float>(max.x, min.y)
    }
    var maxXMaxY: SIMD2<Float> {
        SIMD2<Float>(max.x, max.y)
    }
}

extension Quad {
    static let unit = Quad(min: [0, 0], max: [1, 1])

    /// Clip space quad from (-1, -1) to (1, 1)
    static let clip = Quad(min: [-1, -1], max: [1, 1])
}

extension Quad {
    var flippedY: Quad {
        Quad(min: SIMD2<Float>(min.x, max.y), max: SIMD2<Float>(max.x, min.y))
    }
}

struct TextureBillboardPipeline: Element {
    let vertexShader: VertexShader
    let fragmentShader: FragmentShader

    let specifierA: ColorSource
    let specifierB: ColorSource
    let positions: [SIMD2<Float>]
    let textureCoordinates: [SIMD2<Float>]
    let colorTransformGraph: SimpleStitchedFunctionGraph

    // TODO: #138 Get rid of flippedY
    init(specifierA: ColorSource, specifierB: ColorSource, positions: Quad = .clip, textureCoordinates: Quad = .unit, colorTransform: VisibleFunction? = nil) throws {
        let device = _MTLCreateSystemDefaultDevice()
        #if os(iOS)
        assert(device.supportsFeatureSet(.iOS_GPUFamily4_v1)) // For argument buffers tier. TODO: Look this up.
        #endif
        assert(device.argumentBuffersSupport == .tier2)
        let shaderBundle = Bundle.ultraviolenceExampleShaders().orFatalError()
        let shaderLibrary = try ShaderLibrary(bundle: shaderBundle, namespace: "TextureBillboard")
        self.vertexShader = try shaderLibrary.vertex_main
        self.fragmentShader = try shaderLibrary.fragment_main

        self.specifierA = specifierA
        self.specifierB = specifierB

        self.positions = [
            positions.minXMinY, // bottom-left
            positions.maxXMinY, // bottom-right
            positions.minXMaxY, // top-left
            positions.maxXMaxY  // top-right
        ]
        self.textureCoordinates = [textureCoordinates.minXMaxY, textureCoordinates.maxXMaxY, textureCoordinates.minXMinY, textureCoordinates.maxXMinY]

        let colorTransform = try colorTransform ?? shaderLibrary.function(named: "colorTransformIdentity", type: VisibleFunction.self)
        colorTransformGraph = try SimpleStitchedFunctionGraph(name: "TextureBillboard::colorTransform", function: colorTransform, inputs: 4)
    }

    var body: some Element {
        get throws {
            try RenderPipeline(vertexShader: vertexShader, fragmentShader: fragmentShader) {
                Draw { encoder in
                    encoder.setVertexBytes(positions, length: MemoryLayout<SIMD2<Float>>.stride * positions.count, index: 0)
                    encoder.setVertexBytes(textureCoordinates, length: MemoryLayout<SIMD2<Float>>.stride * textureCoordinates.count, index: 1)
                    encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: positions.count)
                }
                // TODO: We really need an argument buffer abstraction.
                .parameter("specifierA", value: specifierA.toArgumentBuffer())
                .parameter("specifierB", value: specifierB.toArgumentBuffer())
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

extension TextureBillboardPipeline {
    init(specifierA: ColorSource, specifierB: ColorSource, positions: Quad = .clip, textureCoordinates: Quad = .unit, colorTransformFunctionName: String) throws {
        let shaderBundle = Bundle.ultraviolenceExampleShaders().orFatalError()
        let shaderLibrary = try ShaderLibrary(bundle: shaderBundle, namespace: "TextureBillboard")
        let colorTransform = try shaderLibrary.function(named: colorTransformFunctionName, type: VisibleFunction.self)
        try self.init(specifierA: specifierA, specifierB: specifierB, positions: positions, textureCoordinates: textureCoordinates, colorTransform: colorTransform)
    }

    init(specifier: ColorSource, positions: Quad = .clip, textureCoordinates: Quad = .unit, colorTransform: VisibleFunction? = nil) throws {
        try self.init(specifierA: specifier, specifierB: .color([0, 0, 0]), positions: positions, textureCoordinates: textureCoordinates, colorTransform: colorTransform)
    }
}

// TODO: Move - shared with ColorAdjust
struct SimpleStitchedFunctionGraph {
    let stitchedFunctions: [MTLFunction]

    init(name: String, function: VisibleFunction, inputs: Int) throws {
        let function = function.function
        let device = _MTLCreateSystemDefaultDevice()
        let inputs = (0..<inputs).map { MTLFunctionStitchingInputNode(argumentIndex: $0) }
        let node = MTLFunctionStitchingFunctionNode(name: function.name, arguments: inputs, controlDependencies: [])
        let graph = MTLFunctionStitchingGraph(functionName: name, nodes: [node], outputNode: node, attributes: [])
        let stitchedLibraryDescriptor = MTLStitchedLibraryDescriptor(functions: [function], functionGraphs: [graph])
        print(stitchedLibraryDescriptor)
        let stitchedLibrary = try device.makeLibrary(stitchedDescriptor: stitchedLibraryDescriptor)
        stitchedFunctions = [
            try stitchedLibrary.makeFunction(name: name).orThrow(.resourceCreationFailure("Failed to create stitched function"))
        ]
    }

    var linkedFunctions: MTLLinkedFunctions {
        MTLLinkedFunctions(functions: stitchedFunctions)
    }
}
