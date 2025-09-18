import Metal
import UltraviolenceSupport

public struct ComputePass <Content>: Element, BodylessElement, BodylessContentElement where Content: Element {
    internal let label: String?
    internal let content: Content

    public init(label: String? = nil, @ElementBuilder content: () throws -> Content) throws {
        self.label = label
        self.content = try content()
    }

    func workloadEnter(_ node: Node) throws {
        logger?.verbose?.info("Start compute pass: \(label ?? "<unlabeled>") (\(node.element.internalDescription))")
        let commandBuffer = try node.environmentValues.commandBuffer.orThrow(.missingEnvironment(\.commandBuffer))
        let computeCommandEncoder = try commandBuffer._makeComputeCommandEncoder()
        if let label {
            computeCommandEncoder.label = label
        }
        node.environmentValues.computeCommandEncoder = computeCommandEncoder
    }

    func workloadExit(_ node: Node) throws {
        let computeCommandEncoder = try node.environmentValues.computeCommandEncoder.orThrow(.missingEnvironment(\.computeCommandEncoder))
        computeCommandEncoder.endEncoding()
        logger?.verbose?.info("Ending compute pass: \(label ?? "<unlabeled>") (\(node.element.internalDescription))")
    }
}

// MARK: -

public struct ComputePipeline <Content>: Element, BodylessElement, BodylessContentElement where Content: Element {
    private let label: String?
    private let computeKernel: ComputeKernel
    internal let content: Content

    public init(label: String? = nil, computeKernel: ComputeKernel, @ElementBuilder content: () throws -> Content) throws {
        self.label = label
        self.computeKernel = computeKernel
        self.content = try content()
    }

    func setupEnter(_ node: Node) throws {
        let device = try node.environmentValues.device.orThrow(.missingEnvironment(\.device))
        let descriptor = MTLComputePipelineDescriptor()
        if let label {
            descriptor.label = label
        }
        descriptor.computeFunction = computeKernel.function
        if let linkedFunctions = node.environmentValues.linkedFunctions {
            descriptor.linkedFunctions = linkedFunctions
        }
        let (computePipelineState, reflection) = try device.makeComputePipelineState(descriptor: descriptor, options: .bindingInfo)
        node.environmentValues.reflection = Reflection(try reflection.orThrow(.resourceCreationFailure("Failed to create reflection.")))
        node.environmentValues.computePipelineState = computePipelineState
    }

    nonisolated func requiresSetup(comparedTo old: ComputePipeline<Content>) -> Bool {
        // For now, always return false since kernels rarely change after initial setup
        // This prevents pipeline recreation on every frame
        // TODO: Implement proper comparison when shader constants are added
        false
    }
}
