import Metal
internal import UltraviolenceSupport

public struct Compute <Content>: RenderPass where Content: RenderPass {
    public typealias Body = Never

    var threads: MTLSize
    var threadsPerThreadgroup: MTLSize
    var content: Content

    public init(threads: MTLSize, threadsPerThreadgroup: MTLSize, @RenderPassBuilder content: () -> Content) {
        self.threads = threads
        self.threadsPerThreadgroup = threadsPerThreadgroup
        self.content = content()
    }

    public func visit(_ visitor: inout Visitor) throws {
        try visitor.log(label: "Compute.\(#function).") { visitor in
            let device = visitor.device
            let commandBuffer = try visitor.commandBuffer.orThrow(.missingEnvironment(".commandBuffer"))

            try commandBuffer.withComputeCommandEncoder(label: "􀐛Compute.computeCommandEncoder", debugGroup: "􀯕Compute.visit()") { encoder in
                try content.visit(&visitor)
                let computePipelineDescriptor = MTLComputePipelineDescriptor()
                computePipelineDescriptor.computeFunction = try visitor.function(type: .kernel).orThrow(.missingEnvironment("Function"))
                let (pipelineState, reflection) = try device.makeComputePipelineState(descriptor: computePipelineDescriptor, options: .bindingInfo)
                guard let reflection else {
                    throw UltraviolenceError.resourceCreationFailure
                }
                encoder.setComputePipelineState(pipelineState)
                let arguments = visitor.argumentsStack.flatMap { $0 }
                for argument in arguments where argument.functionType == .kernel {
                    let binding = try reflection.bindings.first { $0.name == argument.name }.orThrow(.missingBinding("\(argument.name)"))
                    switch argument.value {
                    case .float3, .float4, .matrix4x4:
                        try withUnsafeBytes(of: argument.value) { buffer in
                            guard let baseAddress = buffer.baseAddress else {
                                throw UltraviolenceError.resourceCreationFailure
                            }
                            encoder.setBytes(baseAddress, length: buffer.count, index: binding.index)
                        }
                    case .texture(let texture):
                        encoder.setTexture(texture, index: binding.index)
                    }
                }
                encoder.dispatchThreads(threads, threadsPerThreadgroup: threadsPerThreadgroup)
            }
        }
    }
}
