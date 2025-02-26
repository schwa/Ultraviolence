import Metal
import UltraviolenceSupport

public struct ComputePass <Content>: Element, BodylessElement, BodylessContentElement where Content: Element {
    internal let content: Content

    public init(@ElementBuilder content: () throws -> Content) throws {
        self.content = try content()
    }

    func workloadEnter(_ node: Node) throws {
        let commandBuffer = try node.environmentValues.commandBuffer.orThrow(.missingEnvironment(\.commandBuffer))
        let computeCommandEncoder = try commandBuffer.makeComputeCommandEncoder().orThrow(.resourceCreationFailure)
        node.environmentValues.computeCommandEncoder = computeCommandEncoder
    }

    func workloadExit(_ node: Node) throws {
        let computeCommandEncoder = try node.environmentValues.computeCommandEncoder.orThrow(.missingEnvironment(\.computeCommandEncoder))
        computeCommandEncoder.endEncoding()
    }
}

// MARK: -

public struct ComputePipeline <Content>: Element, BodylessElement, BodylessContentElement where Content: Element {
    var computeKernel: ComputeKernel
    var content: Content

    public init(computeKernel: ComputeKernel, @ElementBuilder content: () -> Content) {
        self.computeKernel = computeKernel
        self.content = content()
    }

    func setupEnter(_ node: Node) throws {
        let device = try node.environmentValues.device.orThrow(.missingEnvironment(\.device))
        let descriptor = MTLComputePipelineDescriptor()
        descriptor.computeFunction = computeKernel.function
        let (computePipelineState, reflection) = try device.makeComputePipelineState(descriptor: descriptor, options: .bindingInfo)
        node.environmentValues.reflection = Reflection(try reflection.orThrow(.resourceCreationFailure))
        node.environmentValues.computePipelineState = computePipelineState
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

    func workloadEnter(_ node: Node) throws {
        guard let computeCommandEncoder = node.environmentValues.computeCommandEncoder, let computePipelineState = node.environmentValues.computePipelineState else {
            preconditionFailure("No compute command encoder/compute pipeline state found.")
        }
        computeCommandEncoder.setComputePipelineState(computePipelineState)
        computeCommandEncoder.dispatchThreads(threads, threadsPerThreadgroup: threadsPerThreadgroup)
    }
}
