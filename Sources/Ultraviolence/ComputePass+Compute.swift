import Metal
import UltraviolenceSupport

public extension ComputePass {
    @MainActor
    func compute() throws {
        // TODO: This has surprisingly little to do with compute. It's basically the same as offscreen rendererr.
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

        let content = self
            .environment(\.device, device)

        try commandBuffer.withDebugGroup("COMMAND BUFFER") {
            var rootEnvironment = EnvironmentValues()
            rootEnvironment.commandBuffer = commandBuffer
            rootEnvironment.commandQueue = commandQueue

            let content = content
                .environment(\.commandBuffer, commandBuffer)
                .environment(\.commandQueue, commandQueue)
            let graph = try Graph(content: content)
            try graph._process(rootEnvironment: rootEnvironment)
        }
    }
}
