import Metal
import MetalKit
import Ultraviolence

// TODO: Add code to align the texture correctly in the output.
struct BillboardRenderPipeline: Element {
    let texture: MTLTexture
    let slice: Int

    let vertexShader: VertexShader
    let fragmentShader: FragmentShader
    let positions: [SIMD2<Float>]
    let textureCoordinates: [SIMD2<Float>]

    init(texture: MTLTexture, slice: Int = 0) throws {
        self.texture = texture
        self.slice = slice
        let device = MTLCreateSystemDefaultDevice().orFatalError()
        assert(device.argumentBuffersSupport == .tier2)
        let shaderBundle = Bundle.ultraviolenceExampleShaders().orFatalError()
        let shaderLibrary = try ShaderLibrary(bundle: shaderBundle, namespace: "TextureBillboard")

        self.vertexShader = try shaderLibrary.vertex_main
        self.fragmentShader = try shaderLibrary.fragment_main
        positions = [[-1, 1], [-1, -1], [1, 1], [1, -1]]
        textureCoordinates = [[0, 1], [0, 0], [1, 1], [1, 0]]
    }

    var body: some Element {
        get throws {
            try RenderPipeline(vertexShader: vertexShader, fragmentShader: fragmentShader) {
                Draw { encoder in
                    encoder.setVertexBytes(positions, length: MemoryLayout<SIMD2<Float>>.stride * positions.count, index: 0)
                    encoder.setVertexBytes(textureCoordinates, length: MemoryLayout<SIMD2<Float>>.stride * textureCoordinates.count, index: 1)
                    encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: positions.count)
                }
                .parameter("input", value: {

                    if texture.textureType == .type2D {
                        return 0
                    }
                    else if texture.textureType == .typeCube {
                        return 1
                    }
                    else {
                        return 0
                    }

                }())
                .parameter("slice", value: slice)
                .parameter("texture2d", texture: texture.textureType == .type2D ? texture : nil)
                .parameter("textureCube", texture: texture.textureType == .typeCube ? texture : nil)
            }
        }
    }
}
