import Metal
import UltraviolenceSupport

public extension ComputePass {
    @MainActor
    func compute() throws {
        // TODO: This has surprisingly little to do with compute. It's basically the same as offscreen rendererr.
        let device = try MTLCreateSystemDefaultDevice().orThrow(.resourceCreationFailure)
        let commandQueue = try device.makeCommandQueue().orThrow(.resourceCreationFailure)

        let content = CommandBufferElement(completion: .commitAndWaitUntilCompleted) {
            self
        }
        .environment(\.commandQueue, commandQueue)
        .environment(\.device, device)

        let graph = try Graph(content: content)
        try graph.process()
    }
}
