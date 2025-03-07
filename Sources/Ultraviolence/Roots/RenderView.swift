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

    @Environment(\.drawableSizeChange)
    private var drawableSizeChange

    @State
    private var viewModel: RenderViewViewModel<Content>

    public init(@ElementBuilder content: @escaping () throws -> Content) {
        self.device = _MTLCreateSystemDefaultDevice()
        self.content = content
        do {
            self.viewModel = try RenderViewViewModel(device: device, content: content)
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
            viewModel.drawableSizeChange = drawableSizeChange
        }
        .modifier(RenderViewDebugViewModifier<Content>())
        .environment(viewModel)
    }
}

extension EnvironmentValues {
    @Entry
    var drawableSizeChange: ((CGSize) -> Void)?
}

public extension View {
    func onDrawableSizeChange(perform action: @escaping (CGSize) -> Void) -> some View {
        environment(\.drawableSizeChange, action)
    }
}

@Observable
class RenderViewViewModel <Content>: NSObject, MTKViewDelegate where Content: Element {
    var device: MTLDevice
    var commandQueue: MTLCommandQueue
    var content: () throws -> Content
    var lastError: Error?
    var logger: Logger? = Logger()
    var graph: Graph
    var needsSetup = true
    var drawableSizeChange: ((CGSize) -> Void)?

    @MainActor
    init(device: MTLDevice, content: @escaping () throws -> Content) throws {
        self.device = device
        self.content = content
        self.commandQueue = try device._makeCommandQueue()
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

