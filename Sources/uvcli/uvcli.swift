import UniformTypeIdentifiers
import AppKit
import CoreGraphics
import SwiftUI
import Ultraviolence

@main
struct UVCLI {
    static func main() async throws {

        struct MyRenderPass: RenderPass {
            let source = """
                #include <metal_stdlib>

                using namespace metal;

                struct VertexIn {
                    float3 position [[attribute(0)]];
                };

                struct VertexOut {
                    float4 position [[position]];
                };

                [[vertex]] VertexOut vertex_main(const VertexIn in [[stage_in]]) {
                    float4 position = float4(in.position, 1.0);
                    return VertexOut { position };
                }

                [[fragment]] float4 fragment_main() {
                    return float4(1.0, 0.0, 0.0, 1.0);
                }
            """

            var body: some RenderPass {
                try! Draw([Quad2D(origin: [-0.5, -0.5], size: [1, 1])]) {
                    try VertexShader("vertex_main", source: source)
                    try FragmentShader("fragment_main", source: source)
                }
            }
        }

        let renderer = Renderer(MyRenderPass())
        let image = try renderer.render(size: CGSize(width: 1600, height: 1200)).cgImage

        let url = URL(fileURLWithPath: "output.png").absoluteURL
        let imageDestination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(imageDestination, image, nil)
        CGImageDestinationFinalize(imageDestination)
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}
