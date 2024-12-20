import Metal
import UltraviolenceSupport

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

// MARK: -

public struct Compute <Content>: RenderPass, BodylessRenderPass where Content: RenderPass {
    let commandQueue: MTLCommandQueue
    let logging: Bool
    let content: Content

    @Environment(\.commandBuffer)
    var commandBuffer

    @Environment(\.computeCommandEncoder)
    var computeCommandEncoder

    public init(logging: Bool = false, content: () -> Content) throws {
        let device = try MTLCreateSystemDefaultDevice().orThrow(.resourceCreationFailure)

        // TODO: Move UP.
        commandQueue = try device.makeCommandQueue().orThrow(.resourceCreationFailure)

        self.logging = logging
        self.content = content()
    }

    func _expandNode(_ node: Node) throws {
        guard let graph = node.graph else {
            fatalError("Cannot build node tree without a graph.")
        }
        if node.children.isEmpty {
            node.children.append(graph.makeNode())
        }
        try content.expandNode(node.children[0])
    }

    func _enter(_ node: Node) throws {
        let commandBuffer = try commandBuffer.orThrow(.missingEnvironment("commandBuffer"))
        let computeCommandEncoder = try commandBuffer.makeComputeCommandEncoder().orThrow(.resourceCreationFailure)
        // TODO: FIXME - adding environment values here is _too_ late. They do not get propagated to childen.
        node.environmentValues[keyPath: \.computeCommandEncoder] = computeCommandEncoder
    }

    func _exit(_ node: Node) throws {
        computeCommandEncoder!.endEncoding()
    }
}

// MARK: -

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

    func _expandNode(_ node: Node) throws {
        guard let graph = node.graph else {
            fatalError("Cannot build node tree without a graph.")
        }
        if node.children.isEmpty {
            node.children.append(graph.makeNode())
        }
        try content.expandNode(node.children[0])

        let device = try device.orThrow(.missingEnvironment("device"))
        let descriptor = MTLComputePipelineDescriptor()
        descriptor.computeFunction = computeKernel.function
        let (computePipelineState, reflection) = try device.makeComputePipelineState(descriptor: descriptor, options: .bindingInfo)
        node.environmentValues[keyPath: \.reflection] = Reflection(try reflection.orThrow(.resourceCreationFailure))
        node.environmentValues[keyPath: \.computePipelineState] = computePipelineState
    }
}

// MARK: -

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

    func _expandNode(_ node: Node) throws {
        // This line intentionally left blank.
    }

    func drawEnter() {
        guard let computeCommandEncoder, let computePipelineState else {
            fatalError("No compute command encoder/compute pipeline state found.")
        }
        computeCommandEncoder.setComputePipelineState(computePipelineState)
        computeCommandEncoder.dispatchThreads(threads, threadsPerThreadgroup: threadsPerThreadgroup)
    }

    func drawExit() {
        // This line intentionally left blank.
    }
}

public extension Compute {
    @MainActor
    func compute() throws {
        let device = try MTLCreateSystemDefaultDevice().orThrow(.resourceCreationFailure)
        let commandBufferDescriptor = MTLCommandBufferDescriptor()
        if logging {
            try commandBufferDescriptor.addDefaultLogging()
        }
        let commandBuffer = try commandQueue.makeCommandBuffer(descriptor: commandBufferDescriptor).orThrow(.resourceCreationFailure)
        defer {
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
        }

        let root = self
        .environment(\.device, device)
        .environment(\.commandBuffer, commandBuffer)
        .environment(\.commandQueue, commandQueue)
        try root._process()
    }
}
