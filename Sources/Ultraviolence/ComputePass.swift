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

public struct ComputePass <Content>: Element, BodylessElement, BodylessContentElement where Content: Element {
    internal let logging: Bool
    internal let content: Content

    public init(logging: Bool = false, @ElementBuilder content: () throws -> Content) throws {
        self.logging = logging
        self.content = try content()
    }

    func _enter(_ node: Node, environment: inout UVEnvironmentValues) throws {
        let commandBuffer = try environment.commandBuffer.orThrow(.missingEnvironment(\.commandBuffer))
        commandBuffer.pushDebugGroup("COMPUTE PASS")
        logger?.log("Compute.\(#function) makeComputeCommandEncoder")
        let computeCommandEncoder = try commandBuffer.makeComputeCommandEncoder().orThrow(.resourceCreationFailure)
        environment.computeCommandEncoder = computeCommandEncoder
    }

    func _exit(_ node: Node, environment: UVEnvironmentValues) throws {
        logger?.log("Compute.\(#function) endEncoding")
        let computeCommandEncoder = try environment.computeCommandEncoder.orThrow(.missingEnvironment(\.computeCommandEncoder))
        computeCommandEncoder.endEncoding()
        let commandBuffer = try environment.commandBuffer.orThrow(.missingEnvironment(\.commandBuffer))
        commandBuffer.popDebugGroup()
    }
}

// MARK: -

public struct ComputePipeline <Content>: Element, BodylessElement where Content: Element {
    var computeKernel: ComputeKernel
    var content: Content

    @UVEnvironment(\.device)
    var device

    public init(computeKernel: ComputeKernel, @ElementBuilder content: () -> Content) {
        self.computeKernel = computeKernel
        self.content = content()
    }

    func _expandNode(_ node: Node, depth: Int) throws {
        guard let graph = node.graph else {
            preconditionFailure("Cannot build node tree without a graph.")
        }
        if node.children.isEmpty {
            node.children.append(graph.makeNode())
        }
        try content.expandNode(node.children[0], depth: depth + 1)

        let device = try device.orThrow(.missingEnvironment(\.device))
        let descriptor = MTLComputePipelineDescriptor()
        descriptor.computeFunction = computeKernel.function
        let (computePipelineState, reflection) = try device.makeComputePipelineState(descriptor: descriptor, options: .bindingInfo)
        node.environmentValues[keyPath: \.reflection] = Reflection(try reflection.orThrow(.resourceCreationFailure))
        node.environmentValues[keyPath: \.computePipelineState] = computePipelineState
    }
}

// MARK: -

public struct ComputeDispatch: Element, BodylessElement {
    var threads: MTLSize
    var threadsPerThreadgroup: MTLSize

    public init(threads: MTLSize, threadsPerThreadgroup: MTLSize) {
        self.threads = threads
        self.threadsPerThreadgroup = threadsPerThreadgroup
    }

    func _expandNode(_ node: Node, depth: Int) throws {
        // This line intentionally left blank.
    }

    func _enter(_ node: Node, environment: inout UVEnvironmentValues) throws {
        guard let computeCommandEncoder = environment.computeCommandEncoder, let computePipelineState = environment.computePipelineState else {
            preconditionFailure("No compute command encoder/compute pipeline state found.")
        }
        computeCommandEncoder.setComputePipelineState(computePipelineState)
        computeCommandEncoder.dispatchThreads(threads, threadsPerThreadgroup: threadsPerThreadgroup)
    }
}
