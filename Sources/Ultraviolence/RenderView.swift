import Metal
import MetalKit
internal import os
import SwiftUI

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
        // This line intentionally left blank.
    }

    public func draw(in view: MTKView) {
        do {
            guard let currentDrawable = view.currentDrawable else {
                logger?.warning("No current drawable")
                return
            }
            defer {
                currentDrawable.present()
            }
            try commandQueue.withCommandBuffer(label: "􀐛RenderView.Coordinator.commamdBuffer", debugGroup: "􀯕RenderView.Coordinator.draw()") { commandBuffer in
                let currentRenderPassDescriptor = try view.currentRenderPassDescriptor.orThrow(.resourceCreationFailure)
                var visitor = Visitor(device: device)
                let render = Render { content }
                try visitor.with([
                    .renderPassDescriptor(currentRenderPassDescriptor),
                    .commandBuffer(commandBuffer),
                    .commandQueue(commandQueue)
                ]) { visitor in
                    try render.visit(&visitor)
                }
            }
        }
        catch {
            logger?.error("Error when drawing: \(error)")
            lastError = error
        }
    }
}
