import CoreGraphics
import UltraviolenceRedux
import UltraviolenceSupport
import simd
import Metal

@main
struct UVReduxCLI {
    static func main() throws {

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
        // TODO: For basic use cases we can compute the MTLVertexDescriptor from the vertex shader function.
        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<SIMD2<Float>>.size

        let renderPass = Render {
            RenderPipeline(vertexShader: vertexShader, fragmentShader: fragmentShader) {
                Draw { encoder in
                    encoder.setVertexBytes([float3(0, 0.5, 0), float3(-0.5, -0.5, 0), float3(0.5, -0.5, 0)], length: MemoryLayout<float3>.stride * 3, index: 0)
                    encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
                }
            }
            .environment(\.vertexDescriptor, vertexDescriptor)
        }
        let offscreenRenderer = try OffscreenRenderer(size: CGSize(width: 1_600, height: 1_200), content: renderPass)
        let image = try offscreenRenderer.render().cgImage
        print(image)
    }
}
