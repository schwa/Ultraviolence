import Metal
import MetalKit
import Ultraviolence
import UltraviolenceSupport

// TODO: #138 Add code to align the texture correctly in the output.
struct BillboardRenderPipeline: Element {
    let texture: MTLTexture?
    let color: SIMD4<Float>?
    let slice: Int

    let vertexShader: VertexShader
    let fragmentShader: FragmentShader
    let positions: [SIMD2<Float>]
    let textureCoordinates: [SIMD2<Float>]

    init(texture: MTLTexture? = nil, color: SIMD4<Float>? = nil, slice: Int = 0) throws {
        precondition(texture != nil || color != nil, "Either texture or color must be provided")
        self.texture = texture
        self.color = color
        self.slice = slice
        let device = _MTLCreateSystemDefaultDevice()
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
                    if let texture = texture {
                        if texture.textureType == .type2D {
                            return 0
                        }
                        if texture.textureType == .typeCube {
                            return 1
                        }
                    }
                    return 2 // color mode
                }())
                .parameter("slice", value: slice)
                .parameter("solidColor", value: color ?? SIMD4<Float>(1, 0, 1, 1))
                .parameter("texture2d", texture: texture?.textureType == .type2D ? texture : nil)
                .parameter("textureCube", texture: texture?.textureType == .typeCube ? texture : nil)
            }
            .vertexDescriptor(try vertexShader.inferredVertexDescriptor())
        }
    }
}
