internal import UltraviolenceSupport
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
        logger?.log("\(#function)")

        let device = visitor.device
        let commandQueue = try visitor.commandQueue.orThrow(.missingEnvironment(".commandQueue"))
        return try commandQueue.withCommandBuffer(completion: .commitAndWaitUntilCompleted, label: "􀐛Compute.commandBuffer", debugGroup: "􀯕Compute.visit()") { commandBuffer in
            try commandBuffer.withComputeCommandEncoder { encoder in
                try content.visit(&visitor)
                let computePipelineDescriptor = MTLComputePipelineDescriptor()
                computePipelineDescriptor.computeFunction = try visitor.function(type: .kernel).orThrow(.missingEnvironment("Function"))
                let (pipelineState, reflection) = try device.makeComputePipelineState(descriptor: computePipelineDescriptor, options: .bindingInfo)
                guard let reflection else {
                    fatalError("No reflection.")
                }
                encoder.setComputePipelineState(pipelineState)
                let arguments = visitor.argumentsStack.flatMap { $0 }
                for argument in arguments {
                    assert(argument.functionType == .kernel)
                    let binding = try reflection.bindings.first { $0.name == argument.name }.orThrow(.missingBinding("\(argument.name)"))
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


    }
}
