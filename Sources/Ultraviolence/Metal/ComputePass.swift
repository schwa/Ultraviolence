import Metal
import UltraviolenceSupport

public struct ComputePass <Content>: Element, BodylessElement, BodylessContentElement where Content: Element {
    internal let content: Content

    public init(@ElementBuilder content: () throws -> Content) throws {
        self.content = try content()
    }

    func workloadEnter(_ node: Node) throws {
        let commandBuffer = try node.environmentValues.commandBuffer.orThrow(.missingEnvironment(\.commandBuffer))
        let computeCommandEncoder = try commandBuffer._makeComputeCommandEncoder()
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

    public init(computeKernel: ComputeKernel, @ElementBuilder content: () throws -> Content) throws {
        self.computeKernel = computeKernel
        self.content = try content()
    }

    func setupEnter(_ node: Node) throws {
        let device = try node.environmentValues.device.orThrow(.missingEnvironment(\.device))
        let descriptor = MTLComputePipelineDescriptor()
        descriptor.computeFunction = computeKernel.function
        let (computePipelineState, reflection) = try device.makeComputePipelineState(descriptor: descriptor, options: .bindingInfo)
        node.environmentValues.reflection = Reflection(try reflection.orThrow(.resourceCreationFailure("Failed to create reflection.")))
        node.environmentValues.computePipelineState = computePipelineState
    }
}

// MARK: -

public struct ComputeDispatch: Element, BodylessElement {
    private enum Dimensions {
        case threadgroupsPerGrid(MTLSize)
        case threadsPerGrid(MTLSize)
    }

    private var dimensions: Dimensions
    private var threadsPerThreadgroup: MTLSize

    public init(threadgroups: MTLSize, threadsPerThreadgroup: MTLSize) throws {
        self.dimensions = .threadgroupsPerGrid(threadgroups)
        self.threadsPerThreadgroup = threadsPerThreadgroup
    }

    public init(threadsPerGrid: MTLSize, threadsPerThreadgroup: MTLSize) throws {
        let device = _MTLCreateSystemDefaultDevice()
        guard device.supportsFamily(.apple4) else {
            try _throw(UltraviolenceError.deviceCababilityFailure("Non-uniform threadgroup sizes require Apple GPU Family 4+ (A11 or later)"))
        }
        self.dimensions = .threadsPerGrid(threadsPerGrid)
        self.threadsPerThreadgroup = threadsPerThreadgroup
    }

    func expandIntoNode(_ node: Node, context: ExpansionContext) throws {
        // This line intentionally left blank.
    }

    func workloadEnter(_ node: Node) throws {
        guard let computeCommandEncoder = node.environmentValues.computeCommandEncoder, let computePipelineState = node.environmentValues.computePipelineState else {
            preconditionFailure("No compute command encoder/compute pipeline state found.")
        }
        computeCommandEncoder.setComputePipelineState(computePipelineState)

        switch dimensions {
        case .threadgroupsPerGrid(let threadgroupCount):
            computeCommandEncoder.dispatchThreadgroups(threadgroupCount, threadsPerThreadgroup: threadsPerThreadgroup)
        case .threadsPerGrid(let threads):
            computeCommandEncoder.dispatchThreads(threads, threadsPerThreadgroup: threadsPerThreadgroup)
        }
    }
}

