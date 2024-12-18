import Metal
import MetalKit
internal import os
import SwiftUI

// swiftlint:disable force_unwrapping

#if os(macOS)
public struct RenderView <Content>: NSViewRepresentable where Content: RenderPass {
    let device = MTLCreateSystemDefaultDevice()!
    let content: Content

    public init(_ content: Content) {
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
    let content: Content

    public init(_ content: Content) {
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
    var content: Content {
        didSet {
            print("Content did change")
        }
    }
    var lastError: Error?
    var logger: Logger? = Logger()

    init(device: MTLDevice, content: Content) throws {
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
            try commandQueue.withCommandBuffer(completion: .none, label: "􀐛RenderView.Coordinator.commandBuffer", debugGroup: "􀯕RenderView.Coordinator.draw()") { commandBuffer in
                let renderPassDescriptor = view.currentRenderPassDescriptor!

                let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!

                // TODO: Move to init().
                let root = content
                    .environment(\.renderPassDescriptor, renderPassDescriptor)
                    .environment(\.device, device)
                    .environment(\.commandQueue, commandQueue)
                    .environment(\.renderCommandEncoder, renderEncoder) // TODO: Move to Render() render pass.

                let graph = Graph(content: root)
                graph.rebuildIfNeeded()

                try graph.visit { _, node in
                    if let renderPass = node.renderPass as? any BodylessRenderPass {
                        renderPass._setup(node)
                    }
                }
                enter: { node in
                    if let body = node.renderPass as? any BodylessRenderPass {
                        try body.drawEnter()
                    }
                }
                exit: { node in
                    if let body = node.renderPass as? any BodylessRenderPass {
                        try body.drawExit()
                    }
                }
                renderEncoder.endEncoding()
                commandBuffer.commit()
            }
        } catch {
            logger?.error("Error when drawing: \(error)")
            lastError = error
        }
    }
}
