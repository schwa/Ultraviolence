import AppKit
import CoreGraphics
import ImageIO
import Metal
import simd
import Ultraviolence
internal import UltraviolenceSupport
import UniformTypeIdentifiers
import os

enum RedTriangle {
    @MainActor
    static func main() throws {
        let logger = Logger()
        logger.log("\(#function) enter.")
        defer {
            logger.log("\(#function) exit.")
        }



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

        let root = try RenderPass {
            RenderPipeline(vertexShader: vertexShader, fragmentShader: fragmentShader) {
                Draw { encoder in
                    let vertices: [SIMD2<Float>] = [[0, 0.75], [-0.75, -0.75], [0.75, -0.75]]
                    encoder.setVertexBytes(vertices, length: MemoryLayout<SIMD2<Float>>.stride * 3, index: 0)
                    encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
                }
                .parameter("color", SIMD4<Float>([1, 0, 0, 1]))
            }
        }

        //        try MTLCaptureManager.shared().with {
        let offscreenRenderer = try OffscreenRenderer(size: CGSize(width: 1_600, height: 1_200))
        let image = try offscreenRenderer.render(root).cgImage
        let url = URL(fileURLWithPath: "output.png")
        let imageDestination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(imageDestination, image, nil)
        CGImageDestinationFinalize(imageDestination)
        NSWorkspace.shared.activateFileViewerSelecting([url.absoluteURL])
        //        }
    }
}
