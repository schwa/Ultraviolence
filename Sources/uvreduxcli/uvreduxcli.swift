import CoreGraphics
import ImageIO
import Metal
import simd
import UltraviolenceRedux
import UltraviolenceSupport
import UniformTypeIdentifiers

@main
struct UVReduxCLI {
    static func main() throws {
        try ImprovedRedTriangle.main()
    }

    @MainActor
    static func x() throws {
        let source = """
        #include <metal_stdlib>
        using namespace metal;

        struct VertexIn {
            float2 position [[attribute(0)]];
        };

        struct VertexOut {
            float4 position [[position]];
        };

        [[vertex]] VertexOut vertex_main(
            const VertexIn in [[stage_in]]
        ) {
            VertexOut out;
            out.position = float4(in.position, 0.0, 1.0);
            return out;
        }

        [[fragment]] float4 fragment_main(
            VertexOut in [[stage_in]],
            constant float4 &color [[buffer(0)]]
        ) {
            return color;
        }
        """
        let vertexShader = try VertexShader(source: source)
        let fragmentShader = try FragmentShader(source: source)
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.layouts[0].stride = MemoryLayout<SIMD2<Float>>.stride
        let renderPass = Render {
            RenderPipeline(vertexShader: vertexShader, fragmentShader: fragmentShader) {
                Draw { encoder in
                    let vertices: [SIMD2<Float>] = [[0, 0.75], [-0.75, -0.75], [0.75, -0.75]]
                    encoder.setVertexBytes(vertices, length: MemoryLayout<SIMD2<Float>>.stride * 3, index: 0)
                    encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
                }
            }
            .environment(\.vertexDescriptor, vertexDescriptor)
        }
        let offscreenRenderer = try OffscreenRenderer(size: CGSize(width: 1_600, height: 1_200))
        let image = try offscreenRenderer.render(renderPass).cgImage
        let imageDestination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: "output.png") as CFURL, UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(imageDestination, image, nil)
        CGImageDestinationFinalize(imageDestination)
    }
}
