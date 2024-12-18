import Metal
import UltraviolenceSupport

public struct Compute {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let logging: Bool

    public init(logging: Bool = false) throws {
        device = try MTLCreateSystemDefaultDevice().orThrow(.resourceCreationFailure)
        commandQueue = try device.makeCommandQueue().orThrow(.resourceCreationFailure)
        self.logging = logging
    }

    internal func compute(_ body: (MTLComputeCommandEncoder) throws -> Void) throws {
        let commandBufferDescriptor = MTLCommandBufferDescriptor()
        if logging {
            let logStateDescriptor = MTLLogStateDescriptor()
            logStateDescriptor.bufferSize = 16 * 1_024
            let logState = try device.makeLogState(descriptor: logStateDescriptor)

            logState.addLogHandler { _, _, _, message in
                print(message)
            }
            commandBufferDescriptor.logState = logState
        }
        let commandBuffer = try commandQueue.makeCommandBuffer(descriptor: commandBufferDescriptor).orThrow(.resourceCreationFailure)
        let computeCommandEncoder = try commandBuffer.makeComputeCommandEncoder().orThrow(.resourceCreationFailure)
        defer {
            computeCommandEncoder.endEncoding()
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
        }
        try body(computeCommandEncoder)
    }
}

public extension Compute {
    @MainActor
    func compute<Content>(_ content: Content) throws where Content: RenderPass {
        try compute { encoder in
            let root = content
                .environment(\.device, device)
                .environment(\.commandQueue, commandQueue)
                .environment(\.computeCommandEncoder, encoder) // TODO: Move to render

            let graph = Graph(content: root)
    //        graph.dump()

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
        }
    }
}

public struct ComputePipeline <Content>: RenderPass, BodylessRenderPass where Content: RenderPass {
    var computeKernel: ComputeKernel
    var content: Content

    @Environment(\.device)
    var device

    @Environment(\.commandBuffer)
    var commandBuffer

    public init(computeKernel: ComputeKernel, content: () -> Content) {
        self.computeKernel = computeKernel
        self.content = content()
    }

    func _expandNode(_ node: Node) {
        // TODO: Move into BodylessRenderPass
        guard let graph = node.graph else {
            fatalError("Cannot build node tree without a graph.")
        }
        if node.children.isEmpty {
            node.children.append(graph.makeNode())
        }
        content.expandNode(node.children[0])
        node.environmentValues[keyPath: \.computePipelineState] = try! device!.makeComputePipelineState(function: computeKernel.function)
    }
}

public struct ComputeKernel {
    let function: MTLFunction

    public init(source: String, logging: Bool = false) throws {
        let device = try MTLCreateSystemDefaultDevice().orThrow(.resourceCreationFailure)

        let options = MTLCompileOptions()
        options.enableLogging = logging

        let library = try device.makeLibrary(source: source, options: options)
        function = try library.functionNames.compactMap { library.makeFunction(name: $0) }.first { $0.functionType == .kernel }.orThrow(.resourceCreationFailure)
    }
}

public struct ComputeDispatch: RenderPass, BodylessRenderPass {
    var threads: MTLSize
    var threadsPerThreadgroup: MTLSize

    @Environment(\.computePipelineState)
    var computePipelineState

    @Environment(\.computeCommandEncoder)
    var computeCommandEncoder

    public init(threads: MTLSize, threadsPerThreadgroup: MTLSize) {
        self.threads = threads
        self.threadsPerThreadgroup = threadsPerThreadgroup
    }

    func _expandNode(_ node: Node) {
    }

    func drawEnter() {
        computeCommandEncoder!.setComputePipelineState(computePipelineState!)
        computeCommandEncoder!.dispatchThreads(threads, threadsPerThreadgroup: threadsPerThreadgroup)
    }

    func drawExit() {
    }
}
