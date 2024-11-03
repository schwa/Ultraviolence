import Metal

public struct Compute <Content>: RenderPass where Content: RenderPass {
    public typealias Body = Never

    var threadgroupsPerGrid: MTLSize
    var threadsPerThreadgroup: MTLSize
    var content: Content

    public init(threadgroupsPerGrid: MTLSize, threadsPerThreadgroup: MTLSize, @RenderPassBuilder content: () -> Content) {
        self.threadgroupsPerGrid = threadgroupsPerGrid
        self.threadsPerThreadgroup = threadsPerThreadgroup
        self.content = content()
    }

    public func visit(_ visitor: inout Visitor) throws {
        let device = visitor.device
        let commandBuffer = visitor.commandBuffer

        try content.visit(&visitor)
        let computePipelineDescriptor = MTLComputePipelineDescriptor()
        computePipelineDescriptor.computeFunction = visitor.function(type: .kernel)

        let (pipelineState, reflection) = try device.makeComputePipelineState(descriptor: computePipelineDescriptor, options: .bindingInfo)
        let encoder = commandBuffer.makeComputeCommandEncoder()!
        guard let reflection else {
            fatalError("No reflection.")
        }
        let arguments = visitor.argumentsStack.flatMap { $0 }
        for argument in arguments {
            assert(argument.functionType == .kernel)
            guard let binding = reflection.bindings.first(where: { $0.name == argument.name }) else {
                fatalError("Could not find binding for \"\(argument.name)\".")
            }
            switch argument.value {
            case .float3, .float4, .matrix4x4:
                withUnsafeBytes(of: argument.value) { buffer in
                    encoder.setBytes(buffer.baseAddress!, length: buffer.count, index: binding.index)
                }
            case .texture(let texture):
                encoder.setTexture(texture, index: binding.index)
            }
        }

        encoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
    }
}
