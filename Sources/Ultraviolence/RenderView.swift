import SwiftUI
import MetalKit
import Metal

public struct RenderView <Content>: NSViewRepresentable where Content: RenderPass {

    let content: Content

    public init(_ content: Content) {
        self.content = content
    }


    public func makeCoordinator() -> RenderPassCoordinator<Content> {
        .init(content: content)
    }

    public func makeNSView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = MTLCreateSystemDefaultDevice()
        view.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        view.colorPixelFormat = .bgra8Unorm_srgb
        view.delegate = context.coordinator
        return view
    }
        
    public func updateNSView(_ nsView: MTKView, context: Context) {
    }
}

public class RenderPassCoordinator <Content>: NSObject, MTKViewDelegate where Content: RenderPass{

    let content: Content

    init(content: Content) {
        self.content = content
    }

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        print(#function)
    }

    public func draw(in view: MTKView) {

        guard let device = view.device else {
            fatalError()
        }


        let commandQueue = device.makeCommandQueue()!
        let commandBuffer = commandQueue.makeCommandBuffer()!

        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: view.currentRenderPassDescriptor!)!


        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb

        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float4
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<Float>.size * 4
        renderPipelineDescriptor.vertexDescriptor = vertexDescriptor


        var renderState = RenderState(encoder: encoder, pipelineDescriptor: renderPipelineDescriptor)
        try! content.render(&renderState)

        encoder.endEncoding()
        commandBuffer.commit()

        view.currentDrawable!.present()

    }

}
