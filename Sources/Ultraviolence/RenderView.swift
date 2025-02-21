import Metal
import MetalKit
import Observation
internal import os
import QuartzCore
import SwiftUI
import UltraviolenceSupport

public struct RenderView <Content>: View where Content: Element {
    var device = MTLCreateSystemDefaultDevice().orFatalError(.resourceCreationFailure)
    var content: (CAMetalDrawable, MTLRenderPassDescriptor) throws -> Content

    @Observable
    class ViewModel: NSObject, MTKViewDelegate {
        var device: MTLDevice
        var commandQueue: MTLCommandQueue
        var content: (CAMetalDrawable, MTLRenderPassDescriptor) throws -> Content {
            didSet {
                logger?.log("Content did change.")
            }
        }
        var lastError: Error?
        var logger: Logger? = Logger()
        var graph: Graph

        @MainActor
        init(device: MTLDevice, content: @escaping (CAMetalDrawable, MTLRenderPassDescriptor) throws -> Content) throws {
            self.device = device
            self.content = content
            self.commandQueue = try device.makeCommandQueue().orThrow(.resourceCreationFailure)
            self.graph = try Graph(content: EmptyElement())
        }

        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        }

        func draw(in view: MTKView) {
            do {
                let currentDrawable = try view.currentDrawable.orThrow(.undefined)
                defer {
                    currentDrawable.present()
                }

                let renderPassDescriptor = try view.currentRenderPassDescriptor.orThrow(.undefined)

                renderPassDescriptor.depthAttachment.storeAction = .store // TODO: This should be customisable.

                let root = try content(currentDrawable, renderPassDescriptor)
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

    @State
    private var viewModel: ViewModel

    public init(content: @escaping (CAMetalDrawable, MTLRenderPassDescriptor) throws -> Content) {
        self.device = MTLCreateSystemDefaultDevice().orFatalError(.resourceCreationFailure)
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
            // TODO: All of these settings should be configurable.
            view.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
            view.colorPixelFormat = .bgra8Unorm_srgb
            view.depthStencilPixelFormat = .depth32Float
            view.depthStencilAttachmentTextureUsage = [.shaderRead, .renderTarget] // TODO: Assumed
            view.framebufferOnly = false
            return view
        }
        update: { _ in
            viewModel.content = content
        }
        .modifier(RenderViewDebugViewModifier<Content>())
        .environment(viewModel)
    }
}

