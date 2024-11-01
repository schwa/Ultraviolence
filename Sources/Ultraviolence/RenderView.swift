import SwiftUI
import MetalKit
import Metal

public struct RenderView <Content>: NSViewRepresentable where Content: RenderPass {

    let device = MTLCreateSystemDefaultDevice()!
    let content: Content

    public init(_ content: Content) {
        self.content = content
    }

    public func makeCoordinator() -> RenderPassCoordinator<Content> {
        .init(device: device, content: content)
    }

    public func makeNSView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = device
        view.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        view.colorPixelFormat = .bgra8Unorm_srgb
        view.depthStencilPixelFormat = .depth32Float

        view.delegate = context.coordinator
        return view
    }

    public func updateNSView(_ nsView: MTKView, context: Context) {
        context.coordinator.content = content
    }
}

public class RenderPassCoordinator <Content>: NSObject, MTKViewDelegate where Content: RenderPass {
    var device: MTLDevice
    var commandQueue: MTLCommandQueue
    var content: Content

    init(device: MTLDevice, content: Content) {
        self.device = device
        self.content = content
        self.commandQueue = device.makeCommandQueue()!
    }

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }

    public func draw(in view: MTKView) {
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: view.currentRenderPassDescriptor!)!
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
        renderPipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        // TODO: Hardcoded depthStencilDescriptor
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.depthCompareFunction = .lessEqual
        depthStencilDescriptor.isDepthWriteEnabled = true
        var renderState = RenderState(encoder: encoder, pipelineDescriptor: renderPipelineDescriptor, depthStencilDescriptor: depthStencilDescriptor)
        let depthStencilState = device.makeDepthStencilState(descriptor: renderState.depthStencilDescriptor)!
        encoder.setDepthStencilState(depthStencilState)
        encoder.setCullMode(.back)
        encoder.setFrontFacing(.counterClockwise)
        try! content.render(&renderState)
        encoder.endEncoding()
        commandBuffer.commit()
        view.currentDrawable!.present()
    }
}
