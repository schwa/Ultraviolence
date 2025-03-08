import Metal
import MetalKit
import Observation
internal import os
import QuartzCore
import SwiftUI
import UltraviolenceSupport

public extension EnvironmentValues {
    @Entry
    var device: MTLDevice?

    @Entry
    var commandQueue: MTLCommandQueue?

    @Entry
    var drawableSizeChange: ((CGSize) -> Void)?
}

public extension View {
    func onDrawableSizeChange(perform action: @escaping (CGSize) -> Void) -> some View {
        environment(\.drawableSizeChange, action)
    }
}

public struct RenderView <Content>: View where Content: Element {
    var content: () throws -> Content

    @Environment(\.device)
    var device

    @Environment(\.commandQueue)
    var commandQueue

    public init(@ElementBuilder content: @escaping () throws -> Content) {
        self.content = content
    }

    public var body: some View {
        let device = device ?? _MTLCreateSystemDefaultDevice()
        let commandQueue = commandQueue ?? device.makeCommandQueue().orFatalError(.resourceCreationFailure("Failed to create command queue."))
        RenderViewHelper(device: device, commandQueue: commandQueue, content: content)
    }
}

internal struct RenderViewHelper <Content>: View where Content: Element {
    var device: MTLDevice
    var commandQueue: MTLCommandQueue
    var content: () throws -> Content

    @Environment(\.self)
    private var environment

    @Environment(\.drawableSizeChange)
    private var drawableSizeChange

    @State
    private var viewModel: RenderViewViewModel<Content>

    init(device: MTLDevice, commandQueue: MTLCommandQueue, @ElementBuilder content: @escaping () throws -> Content) {
        do {
            self.device = device
            self.commandQueue = commandQueue
            self.viewModel = try RenderViewViewModel(device: device, commandQueue: commandQueue, content: content)
            self.content = content
        }
        catch {
            preconditionFailure("Failed to create RenderView.ViewModel: \(error)")
        }
    }

    var body: some View {
        ViewAdaptor<MTKView> {
            MTKView()
        }
        update: { view in
            view.device = device
            view.delegate = viewModel
            view.configure(from: environment)
            viewModel.content = content
            viewModel.drawableSizeChange = drawableSizeChange
        }
        .modifier(RenderViewDebugViewModifier<Content>())
        .environment(viewModel)
    }
}

@Observable
internal class RenderViewViewModel <Content>: NSObject, MTKViewDelegate where Content: Element {
    var device: MTLDevice
    var commandQueue: MTLCommandQueue
    var content: () throws -> Content
    var lastError: Error?
    var logger: Logger? = Logger()
    var graph: Graph
    var needsSetup = true
    var drawableSizeChange: ((CGSize) -> Void)?

    @MainActor
    init(device: MTLDevice, commandQueue: MTLCommandQueue, content: @escaping () throws -> Content) throws {
        self.device = device
        self.content = content
        self.commandQueue = commandQueue
        self.graph = try Graph(content: EmptyElement())
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // TODO: #45 We may want to actually do graph.processSetup here so that (expensive) setup is not done at render time. But this is made a lot more difficult because we are wrapping the content in CommandBufferElement and a ton of .environment setting.
        needsSetup = true
        drawableSizeChange?(size)
    }

    func draw(in view: MTKView) {
        do {
            let currentDrawable = try view.currentDrawable.orThrow(.generic("No drawable available"))
            defer {
                currentDrawable.present()
            }
            let currentRenderPassDescriptor = try view.currentRenderPassDescriptor.orThrow(.generic("No render pass descriptor available"))
            let content = try CommandBufferElement(completion: .commit) {
                try self.content()
            }
            .environment(\.device, device)
            .environment(\.commandQueue, commandQueue)
            .environment(\.renderPassDescriptor, currentRenderPassDescriptor)
            .environment(\.currentDrawable, currentDrawable)
            .environment(\.drawableSize, view.drawableSize)

            // TODO: #25 Find a way to detect if graph has changed and set needsSetup to true. I am assuming we get a whole new graph every time - can we confirm this is true and too much work is being done?
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
