import Metal
import MetalKit
import Ultraviolence
import UltraviolenceSupport

// TODO: #138 Add code to align the texture correctly in the output.
struct BillboardRenderPipeline: Element {
    let specifier: Texture2DSpecifier
    let slice: Int

    let vertexShader: VertexShader
    let fragmentShader: FragmentShader
    let positions: [SIMD2<Float>]
    let textureCoordinates: [SIMD2<Float>]

    init(specifier: Texture2DSpecifier, slice: Int = 0, flippedY: Bool = false) throws {
        self.specifier = specifier
        self.slice = slice
        let device = _MTLCreateSystemDefaultDevice()
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
    }

    var body: some Element {
        get throws {
            try RenderPipeline(vertexShader: vertexShader, fragmentShader: fragmentShader) {

                let specifierArgumentBuffer = specifier.toTexture2DSpecifierArgmentBuffer()

                Draw { encoder in
                    encoder.setVertexBytes(positions, length: MemoryLayout<SIMD2<Float>>.stride * positions.count, index: 0)
                    encoder.setVertexBytes(textureCoordinates, length: MemoryLayout<SIMD2<Float>>.stride * textureCoordinates.count, index: 1)
                    encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: positions.count)
                }
                .parameter("specifier", value: specifierArgumentBuffer)
                .useResource(specifier.texture2D, usage: .read, stages: .fragment)
                .useResource(specifier.textureCube, usage: .read, stages: .fragment)
                .useResource(specifier.depth2D, usage: .read, stages: .fragment)
                .parameter("slice", value: slice)
            }
            .vertexDescriptor(try vertexShader.inferredVertexDescriptor())
        }
    }
}
