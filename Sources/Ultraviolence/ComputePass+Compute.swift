import Metal
import UltraviolenceSupport

public extension ComputePass {
    @MainActor
    func compute() throws {
        let device = try MTLCreateSystemDefaultDevice().orThrow(.resourceCreationFailure)
        let commandBufferDescriptor = MTLCommandBufferDescriptor()
        if logging {
            try commandBufferDescriptor.addDefaultLogging()
        }
        let commandQueue = try device.makeCommandQueue().orThrow(.resourceCreationFailure)
        let commandBuffer = try commandQueue.makeCommandBuffer(descriptor: commandBufferDescriptor).orThrow(.resourceCreationFailure)
        defer {
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
        }

        try commandBuffer.withDebugGroup("COMMAND BUFFER") {
            let root = self
                .environment(\.device, device)
                .environment(\.commandBuffer, commandBuffer)
                .environment(\.commandQueue, commandQueue)
            let graph = try Graph(content: root)
            try graph._process(rootEnvironment: .init()) // TODO: use root environment
        }
    }
}
