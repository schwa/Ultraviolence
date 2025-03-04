import Metal
import MetalKit
import Ultraviolence

// TODO: Add code to align the texture correctly in the output.
struct BillboardRenderPipeline: Element {
    let texture: MTLTexture

    let source = """
    #include <metal_stdlib>
    using namespace metal;

    struct VertexIn {
        float2 position [[attribute(0)]];
        float2 textureCoordinate [[attribute(1)]];
    };

    struct VertexOut {
        float4 position [[position]];
        float2 textureCoordinate;
    };

    [[vertex]] VertexOut vertex_main(
        const VertexIn in [[stage_in]]
    ) {
        VertexOut out;
        out.position = float4(in.position, 0.0, 1.0);
        out.textureCoordinate = in.textureCoordinate;
        return out;
    }

    [[fragment]] float4 fragment_main(
        VertexOut in [[stage_in]],
        texture2d<float> texture [[texture(1)]]
    ) {

        constexpr sampler s;
        return texture.sample(s, in.textureCoordinate);
    }
    """

    let vertexShader: VertexShader
    let fragmentShader: FragmentShader
    let positions: [SIMD2<Float>]
    let textureCoordinates: [SIMD2<Float>]

    init(texture: MTLTexture) throws {
        self.texture = texture
        self.vertexShader = try VertexShader(source: source)
        self.fragmentShader = try FragmentShader(source: source)
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
                .parameter("texture", texture: texture)
            }
        }
    }
}
