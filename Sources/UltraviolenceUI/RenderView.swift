import Metal
import MetalKit
import Observation
internal import os
import QuartzCore
import SwiftUI
import Ultraviolence
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
    @ObservationIgnored
    var device: MTLDevice

    @ObservationIgnored
    var commandQueue: MTLCommandQueue

    @ObservationIgnored

    var content: () throws -> Content
    var lastError: Error?

    @ObservationIgnored
    var system: System

    @ObservationIgnored
    var needsSetup = true

    @ObservationIgnored
    var drawableSizeChange: ((CGSize) -> Void)?

    @ObservationIgnored
    var signpostID = signposter?.makeSignpostID()

    var frame: Int = 0

    @MainActor
    init(device: MTLDevice, commandQueue: MTLCommandQueue, content: @escaping () throws -> Content) throws {
        self.device = device
        self.content = content
        self.commandQueue = commandQueue
        self.system = System()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // TODO: #45 We may want to actually do graph.processSetup here so that (expensive) setup is not done at render time. But this is made a lot more difficult because we are wrapping the content in CommandBufferElement and a ton of .environment setting.
        needsSetup = true
        drawableSizeChange?(size)
    }

    func draw(in view: MTKView) {
        do {
            if RenderViewDebugging.logFrame {
                logger?.verbose?.info("Drawing frame #\(self.frame)")
            }
            try withIntervalSignpost(signposter, name: "RenderViewViewModel.draw()", id: signpostID) {
                let currentDrawable = try view.currentDrawable.orThrow(.resourceCreationFailure("No drawable available"))
                defer {
                    currentDrawable.present()
                    frame += 1
                }
                let currentRenderPassDescriptor = try view.currentRenderPassDescriptor.orThrow(.resourceCreationFailure("No render pass descriptor available"))
                let content = try CommandBufferElement(completion: .commit) {
                    try self.content()
                }
                .environment(\.device, device)
                .environment(\.commandQueue, commandQueue)
                .environment(\.renderPassDescriptor, currentRenderPassDescriptor)
                .environment(\.renderPipelineDescriptor, MTLRenderPipelineDescriptor())
                .environment(\.currentDrawable, currentDrawable)
                .environment(\.drawableSize, view.drawableSize)

                do {
                    // TODO: #25 Find a way to detect if graph has changed and set needsSetup to true. I am assuming we get a whole new graph every time - can we confirm this is true and too much work is being done?
                    try system.update(root: content)
                    // Check if any new nodes need setup after updating content
                    if needsSetup {
                        try system.processSetup()
                        needsSetup = false
                    }
                    try system.processWorkload()
                } catch {
                    handle(error: error)
                }
            }
        } catch {
            handle(error: error)
        }
    }

    @MainActor
    func handle(error: Error) {
        logger?.error("Error when drawing frame #\(self.frame): \(error)")
        if RenderViewDebugging.logContent {
            if let content = try? self.content() {
                logger?.error("Content: \(String(describing: content))")
            }
        }
        if RenderViewDebugging.fatalErrorOnCatch {
            fatalError("Error when drawing #\(self.frame): \(error)")
        }
        lastError = error
    }
}

public struct RenderViewDebugging {
    @MainActor
    static var logFrame = true
    @MainActor
    static var fatalErrorOnCatch = true
    @MainActor
    static var logContent = true
}
