import SwiftUI
import MetalKit
import Metal
internal import os

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

// MARK: -

public class RenderPassCoordinator <Content>: NSObject, MTKViewDelegate where Content: RenderPass {
    var device: MTLDevice
    var commandQueue: MTLCommandQueue
    var content: Content
    var lastError: Error?
    var logger: Logger? = Logger()

    init(device: MTLDevice, content: Content) {
        self.device = device
        self.content = content
        self.commandQueue = device.makeCommandQueue()!
    }

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }

    public func draw(in view: MTKView) {
        let commandBuffer = commandQueue.makeCommandBuffer()!
        commandBuffer.withDebugGroup(label: "RenderPassView") {
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: view.currentRenderPassDescriptor!)!
            let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
            renderPipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
            renderPipelineDescriptor.depthAttachmentPixelFormat = view.depthStencilPixelFormat
            var visitor = Visitor(device: device)
            do {
                try visitor.with([.commandBuffer(commandBuffer), .renderEncoder(encoder), .renderPipelineDescriptor(renderPipelineDescriptor)]) { visitor in
                    try content.visit(&visitor)
                }
            }
            catch {
                logger?.error("Error when visiting render passes: \(error)")
                lastError = error
            }
            encoder.endEncoding()
            commandBuffer.commit()
            view.currentDrawable!.present()
        }
    }
}
