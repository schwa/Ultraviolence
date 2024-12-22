import Metal
import MetalKit
internal import os
import QuartzCore
import SwiftUI

#if os(macOS)
public struct RenderView <Content>: NSViewRepresentable where Content: Element {
    var device = MTLCreateSystemDefaultDevice().orFatalError(.resourceCreationFailure)
    var content: (CAMetalDrawable, MTLRenderPassDescriptor) -> Content

    public init(_ content: @escaping (CAMetalDrawable, MTLRenderPassDescriptor) -> Content) {
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
public struct RenderView <Content>: UIViewRepresentable where Content: Element {
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

public class RenderPassCoordinator <Content>: NSObject, MTKViewDelegate where Content: Element {
    var device: MTLDevice
    var commandQueue: MTLCommandQueue
    var content: (CAMetalDrawable, MTLRenderPassDescriptor) -> Content {
        didSet {
            print("Content did change")
        }
    }
    var lastError: Error?
    var logger: Logger? = Logger()
    var graph: Graph

    @MainActor
    init(device: MTLDevice, content: @escaping (CAMetalDrawable, MTLRenderPassDescriptor) -> Content) throws {
        self.device = device
        self.content = content
        self.commandQueue = try device.makeCommandQueue().orThrow(.resourceCreationFailure)
        self.graph = try Graph(content: EmptyElement())
    }

    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // This line intentionally left blank.
    }

    public func draw(in view: MTKView) {
        do {
            let currentDrawable = try view.currentDrawable.orThrow(.undefined)
            defer {
                currentDrawable.present()
            }

            let renderPassDescriptor = try view.currentRenderPassDescriptor.orThrow(.undefined)

            renderPassDescriptor.depthAttachment.storeAction = .store // TODO: This should be customisable.

            let root = content(currentDrawable, renderPassDescriptor)
                .environment(\.renderPassDescriptor, renderPassDescriptor)
                .environment(\.device, device)

            try graph.updateContent(content: root)

            try commandQueue.withCommandBuffer(completion: .none, label: "􀐛RenderView.Coordinator.commandBuffer", debugGroup: "􀯕RenderView.Coordinator.draw()") { commandBuffer in
                defer {
                    commandBuffer.commit()
                }
                var environment = EnvironmentValues()
                environment.commandQueue = commandQueue
                environment.commandBuffer = commandBuffer
                try graph._process(rootEnvironment: environment, log: false)
            }
        } catch {
            logger?.error("Error when drawing: \(error)")
            lastError = error
        }
    }
}
