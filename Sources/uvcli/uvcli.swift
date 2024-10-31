import UniformTypeIdentifiers
import AppKit
import CoreGraphics
import simd
import SwiftUI
import Ultraviolence

struct UnlitRenderPass: RenderPass {
    var geometry: Geometry
    var cameraMatrix: simd_float4x4

    var body: some RenderPass {
        ForEach_(geometry) { geometry in
            Draw([geometry]) {
                VertexShader("Example::VertexShader")
                    .uniform("model", geometry /* .transform */)
                    .uniform("view", cameraMatrix)
                FragmentShader("Example::FragmentShader")
                    .uniform("color", Color.pink)
            }
        }
    }
}

struct UpscalingPass <Content>: RenderPass where Content: RenderPass {
    var factor: Float = 2
    var content: Content
    var input: Texture

    @RenderState
    var fullSizeTexture: Texture

    init(factor: Float, input: Texture, @RenderPassBuilder content: () -> Content) {
        self.factor = factor
        self.content = content()
        self.input = input
        self.fullSizeTexture = .init()
    }

    var body: some RenderPass {
        List_ {
            content
                .renderTarget(input)
            MetalFXUpscaler(input: input)
                .renderTarget(fullSizeTexture)
            Blit(input: fullSizeTexture)
        }
    }
}

struct MyRenderView: View {
    var geometry: Geometry
    var cameraMatrix: simd_float4x4

    @RenderState
    var downsizedTexture: Texture

    var body: some View {
        RenderView {
            UpscalingPass(factor: 2, input: downsizedTexture) {
                UnlitRenderPass(geometry: geometry, cameraMatrix: cameraMatrix)
            }
        }
        .onDrawableSizeChange(initial: true) { size in
            downsizedTexture = Texture(size: size)
        }
    }
}

@main
struct UVCLI {
    
    static func main() async throws {
        let source = """
            #include <metal_stdlib>

            using namespace metal;

            struct VertexIn {
                float4 position [[attribute(0)]];
            };

            struct VertexOut {
                float4 position [[position]];
            };

            [[vertex]] VertexOut vertex_main(const VertexIn in [[stage_in]], constant float4x4& modelViewProjection [[buffer(0)]]) {
                return VertexOut { modelViewProjection * in.position };
            }

            [[fragment]] float4 fragment_main() {
                return float4(1.0, 0.0, 0.0, 1.0);
            }
        """

        let renderer = Renderer {
            Draw([Quad2D(origin: [-1, -1], size: [1, 1])]) {
                try! VertexShader("vertex_main", source: source)
                try! FragmentShader("fragment_main", source: source)
            }
        }
        let image = try renderer.render(size: CGSize(width: 1600, height: 1200)).cgImage

        let url = URL(fileURLWithPath: "output.png").absoluteURL
        let imageDestination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(imageDestination, image, nil)
        CGImageDestinationFinalize(imageDestination)
        //NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}
