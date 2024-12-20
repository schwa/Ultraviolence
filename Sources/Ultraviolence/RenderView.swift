import Metal
import MetalKit
internal import os
import SwiftUI

#if os(macOS)
public struct RenderView <Content>: NSViewRepresentable where Content: RenderPass {
    let device = MTLCreateSystemDefaultDevice().orFatalError(.resourceCreationFailure)
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
        // TODO: All of these settings should be configurable.
        view.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        view.colorPixelFormat = .bgra8Unorm_srgb
        view.depthStencilPixelFormat = .depth32Float
        view.depthStencilAttachmentTextureUsage = [.shaderRead, .renderTarget] // TODO: Assumed
        view.framebufferOnly = false  // TODO: Assumed
        return view
    }

    public func updateNSView(_ nsView: MTKView, context: Context) {
        context.coordinator.content = content
    }
}
#elseif os(iOS)
public struct RenderView <Content>: UIViewRepresentable where Content: RenderPass {
    let device = MTLCreateSystemDefaultDevice().orFatalError(.resourceCreationFailure)
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
        // TODO: All of these settings should be configurable.
        view.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        view.colorPixelFormat = .bgra8Unorm_srgb
        view.depthStencilPixelFormat = .depth32Float
        view.depthStencilAttachmentTextureUsage = [.shaderRead, .renderTarget] // TODO: Assumed
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
                let renderPassDescriptor = try view.currentRenderPassDescriptor.orThrow(.undefined)

                let renderEncoder = try commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor).orThrow(.resourceCreationFailure)

                // TODO: Move to init().
                let root = content
                    .environment(\.renderPassDescriptor, renderPassDescriptor)
                    .environment(\.device, device)
                    .environment(\.commandQueue, commandQueue)
                    .environment(\.renderCommandEncoder, renderEncoder) // TODO: Move to Render() render pass.

                try root._process()

                renderEncoder.endEncoding()
                commandBuffer.commit()
            }
        } catch {
            logger?.error("Error when drawing: \(error)")
            lastError = error
        }
    }
}
