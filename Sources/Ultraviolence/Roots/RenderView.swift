import Metal
import MetalKit
import Observation
internal import os
import QuartzCore
import SwiftUI
import UltraviolenceSupport

public struct RenderView <Content>: View where Content: Element {
    var device = _MTLCreateSystemDefaultDevice()
    var content: () throws -> Content

    @Environment(\.self)
    private var environment

    @Observable
    class ViewModel: NSObject, MTKViewDelegate {
        var device: MTLDevice
        var commandQueue: MTLCommandQueue
        var content: () throws -> Content
        var lastError: Error?
        var logger: Logger? = Logger()
        var graph: Graph
        var needsSetup = true

        @MainActor
        init(device: MTLDevice, content: @escaping () throws -> Content) throws {
            self.device = device
            self.content = content
            self.commandQueue = try device._makeCommandQueue()
            self.graph = try Graph(content: EmptyElement())
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        }

        func draw(in view: MTKView) {
            do {
                let currentDrawable = try view.currentDrawable.orThrow(.generic("No drawable available"))
                defer {
                    currentDrawable.present()
                }
                let renderPassDescriptor = try view.currentRenderPassDescriptor.orThrow(.generic("No render pass descriptor available"))
                let content = try CommandBufferElement(completion: .commit) {
                    try self.content()
                }
                .environment(\.device, device)
                .environment(\.commandQueue, commandQueue)
                .environment(\.renderPassDescriptor, renderPassDescriptor)
                .environment(\.currentDrawable, currentDrawable)
                .environment(\.drawableSize, view.drawableSize)

                // TODO: Find a way to detect if graph has changed and set needsSetup to true
                try graph.updateContent(content: content)
                if needsSetup {
                    try graph.processSetup()
                    needsSetup = false
                }
                try graph.processWorkload()
            } catch {
                logger?.error("Error when drawing: \(error)")
                lastError = error
            }
        }
    }

    @State
    private var viewModel: ViewModel

    public init(@ElementBuilder content: @escaping () throws -> Content) {
        self.device = _MTLCreateSystemDefaultDevice()
        self.content = content
        do {
            self.viewModel = try ViewModel(device: device, content: content)
        }
        catch {
            preconditionFailure("Failed to create RenderView.ViewModel: \(error)")
        }
    }

    public var body: some View {
        ViewAdaptor {
            let view = MTKView()
            view.device = device
            view.delegate = viewModel
            view.configure(from: environment)
            return view
        }
        update: { _ in
            viewModel.content = content
        }
        .modifier(RenderViewDebugViewModifier<Content>())
        .environment(viewModel)
    }
}

// MARK: -

internal extension EnvironmentValues {
    // swiftlint:disable discouraged_optional_boolean
    @Entry var metalFramebufferOnly: Bool?
    @Entry var metalDepthStencilAttachmentTextureUsage: MTLTextureUsage?
    @Entry var metalMultisampleColorAttachmentTextureUsage: MTLTextureUsage?
    @Entry var metalPresentsWithTransaction: Bool?
    @Entry var metalColorPixelFormat: MTLPixelFormat?
    @Entry var metalDepthStencilPixelFormat: MTLPixelFormat?
    @Entry var metalDepthStencilStorageMode: MTLStorageMode?
    @Entry var metalSampleCount: Int?
    @Entry var metalClearColor: MTLClearColor?
    @Entry var metalClearDepth: Double?
    @Entry var metalClearStencil: UInt32?
    @Entry var metalPreferredFramesPerSecond: Int?
    @Entry var metalEnableSetNeedsDisplay: Bool?
    @Entry var metalAutoResizeDrawable: Bool?
    @Entry var metalIsPaused: Bool?
    #if os(macOS)
    @Entry var metalColorspace: CGColorSpace?
    #endif
    // swiftlint:enable discouraged_optional_boolean
}

public extension View {
    func metalFramebufferOnly(_ value: Bool) -> some View {
        self.environment(\.metalFramebufferOnly, value)
    }
    func metalDepthStencilAttachmentTextureUsage(_ value: MTLTextureUsage) -> some View {
        self.environment(\.metalDepthStencilAttachmentTextureUsage, value)
    }
    func metalMultisampleColorAttachmentTextureUsage(_ value: MTLTextureUsage) -> some View {
        self.environment(\.metalMultisampleColorAttachmentTextureUsage, value)
    }
    func metalPresentsWithTransaction(_ value: Bool) -> some View {
        self.environment(\.metalPresentsWithTransaction, value)
    }
    func metalColorPixelFormat(_ value: MTLPixelFormat) -> some View {
        self.environment(\.metalColorPixelFormat, value)
    }
    func metalDepthStencilPixelFormat(_ value: MTLPixelFormat) -> some View {
        self.environment(\.metalDepthStencilPixelFormat, value)
    }
    func metalDepthStencilStorageMode(_ value: MTLStorageMode) -> some View {
        self.environment(\.metalDepthStencilStorageMode, value)
    }
    func metalSampleCount(_ value: Int) -> some View {
        self.environment(\.metalSampleCount, value)
    }
    func metalClearColor(_ value: MTLClearColor) -> some View {
        self.environment(\.metalClearColor, value)
    }
    func metalClearDepth(_ value: Double) -> some View {
        self.environment(\.metalClearDepth, value)
    }
    func metalClearStencil(_ value: UInt32) -> some View {
        self.environment(\.metalClearStencil, value)
    }
    func metalPreferredFramesPerSecond(_ value: Int) -> some View {
        self.environment(\.metalPreferredFramesPerSecond, value)
    }
    func metalEnableSetNeedsDisplay(_ value: Bool) -> some View {
        self.environment(\.metalEnableSetNeedsDisplay, value)
    }
    func metalAutoResizeDrawable(_ value: Bool) -> some View {
        self.environment(\.metalAutoResizeDrawable, value)
    }
    func metalIsPaused(_ value: Bool) -> some View {
        self.environment(\.metalIsPaused, value)
    }
    #if os(macOS)
    func metalColorspace(_ value: CGColorSpace?) -> some View {
        self.environment(\.metalColorspace, value)
    }
    #endif
}

extension MTKView {
    // swiftlint:disable:next cyclomatic_complexity
    func configure(from environment: EnvironmentValues) {
        if let value = environment.metalFramebufferOnly {
            self.framebufferOnly = value
        }
        if let value = environment.metalDepthStencilAttachmentTextureUsage {
            self.depthStencilAttachmentTextureUsage = value
        }
        if let value = environment.metalMultisampleColorAttachmentTextureUsage {
            self.multisampleColorAttachmentTextureUsage = value
        }
        if let value = environment.metalPresentsWithTransaction {
            self.presentsWithTransaction = value
        }
        if let value = environment.metalColorPixelFormat {
            self.colorPixelFormat = value
        }
        if let value = environment.metalDepthStencilPixelFormat {
            self.depthStencilPixelFormat = value
        }
        if let value = environment.metalDepthStencilStorageMode {
            self.depthStencilStorageMode = value
        }
        if let value = environment.metalSampleCount {
            self.sampleCount = value
        }
        if let value = environment.metalClearColor {
            self.clearColor = value
        }
        if let value = environment.metalClearDepth {
            self.clearDepth = value
        }
        if let value = environment.metalClearStencil {
            self.clearStencil = value
        }
        if let value = environment.metalPreferredFramesPerSecond {
            self.preferredFramesPerSecond = value
        }
        if let value = environment.metalEnableSetNeedsDisplay {
            self.enableSetNeedsDisplay = value
        }
        if let value = environment.metalAutoResizeDrawable {
            self.autoResizeDrawable = value
        }
        if let value = environment.metalIsPaused {
            self.isPaused = value
        }
        #if os(macOS)
        if let value = environment.metalColorspace {
            self.colorspace = value
        }
        #endif
    }
}
