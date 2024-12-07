import Metal
import MetalKit
internal import os
import SwiftUI
import Ultraviolence

#if os(macOS)
public struct RenderView <Content>: NSViewRepresentable where Content: RenderPass {
    let device = MTLCreateSystemDefaultDevice()!
    let content: (MTLRenderPassDescriptor) -> Content

    public init(@RenderPassBuilder _ content: @escaping (MTLRenderPassDescriptor) -> Content) {
        self.content = content
    }

    public func makeCoordinator() -> RenderPassCoordinator<Content> {
        do {
            return try .init(device: device, content: content)
        } catch {
            fatalError("Failed to create render pass coordinator: \(error)")
        }
    }

    public func makeNSView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = device
        view.delegate = context.coordinator
        // TODO: To be honest all of these settings should be configurable.
        view.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        view.colorPixelFormat = .bgra8Unorm_srgb
        view.depthStencilPixelFormat = .depth32Float
        view.depthStencilAttachmentTextureUsage = [.shaderRead, .renderTarget]
        view.framebufferOnly = false
        return view
    }

    public func updateNSView(_ nsView: MTKView, context: Context) {
        context.coordinator.content = content
    }
}
#elseif os(iOS)
public struct RenderView <Content>: UIViewRepresentable where Content: RenderPass {
    let device = MTLCreateSystemDefaultDevice()!
    let content: (MTLRenderPassDescriptor) -> Content

    public init(@RenderPassBuilder _ content: @escaping (MTLRenderPassDescriptor) -> Content) {
        self.content = content
    }

    public func makeCoordinator() -> RenderPassCoordinator<Content> {
        // swiftlint:disable:next force_try
        try! .init(device: device, content: content)
    }

    public func makeUIView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = device
        view.delegate = context.coordinator
        // TODO: To be honest all of these settings should be configurable.
        view.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        view.colorPixelFormat = .bgra8Unorm_srgb
        view.depthStencilPixelFormat = .depth32Float
        view.depthStencilAttachmentTextureUsage = [.shaderRead, .renderTarget] // TODO
        view.framebufferOnly = false
        return view
    }

    public func updateUIView(_ nsView: MTKView, context: Context) {
        context.coordinator.content = content
    }
}
#endif

// MARK: -

public class RenderPassCoordinator <Content>: NSObject, MTKViewDelegate where Content: RenderPass {
    var device: MTLDevice
    var commandQueue: MTLCommandQueue
    var content: (MTLRenderPassDescriptor) -> Content
    var lastError: Error?
    var logger: Logger? = Logger()

    init(device: MTLDevice, content: @escaping (MTLRenderPassDescriptor) -> Content) throws {
        self.device = device
        self.content = content
        self.commandQueue = try device.makeCommandQueue().orThrow(.resourceCreationFailure)
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
            try commandQueue.withCommandBuffer(label: "􀐛RenderView.Coordinator.commandBuffer", debugGroup: "􀯕RenderView.Coordinator.draw()") { commandBuffer in
                let currentRenderPassDescriptor = try view.currentRenderPassDescriptor.orThrow(.resourceCreationFailure)

                currentRenderPassDescriptor.depthAttachment.storeAction = .store

                logger?.log("#####################################################")
                var visitor = Visitor(device: device)
                try visitor.with([
                    .renderPassDescriptor(currentRenderPassDescriptor),
                    .commandBuffer(commandBuffer)
                ]) { visitor in
                    try content(currentRenderPassDescriptor).visit(visitor: &visitor)
                }
            }
        } catch {
            logger?.error("Error when drawing: \(error)")
            lastError = error
        }
    }
}
