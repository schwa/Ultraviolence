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
            // TODO: We may want to actually do graph.processSetup here so that (expensive) setup is not done at render time. But this is made a lot more difficult because we are wrapping the content in CommandBufferElement and a ton of .environment setting. https://github.com/schwa/Ultraviolence/issues/45
            needsSetup = true
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

                // TODO: Find a way to detect if graph has changed and set needsSetup to true. I am assuming we get a whole new graph every time - can we confirm this is true and too much work is being done?
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
