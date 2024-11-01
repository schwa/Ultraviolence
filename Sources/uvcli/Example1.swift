import Ultraviolence
import SwiftUI
import simd

struct UnlitRenderPass: RenderPass {
    var geometry: Geometry
    var cameraMatrix: simd_float4x4

    var body: some RenderPass {
        ForEach(geometry) { geometry in
            try Draw([geometry]) {
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

    @State_
    var fullSizeTexture: Texture

    init(factor: Float, input: Texture, @RenderPassBuilder content: () -> Content) {
        self.factor = factor
        self.content = content()
        self.input = input
        self.fullSizeTexture = .init()
    }

    var body: some RenderPass {
        Chain {
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

    @State_
    var downsizedTexture: Texture

    var body: some View {
        RenderView(UpscalingPass(factor: 2, input: downsizedTexture) {
            UnlitRenderPass(geometry: geometry, cameraMatrix: cameraMatrix)
        })
        .onDrawableSizeChange(initial: true) { size in
            downsizedTexture = Texture(size: size)
        }
    }
}
