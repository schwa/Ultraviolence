import Metal
import UltraviolenceSupport

public extension ComputePass {
    @MainActor
    func compute() throws {
        // TODO: This has surprisingly little to do with compute. It's basically the same as offscreen rendererr.
        let device = try MTLCreateSystemDefaultDevice().orThrow(.resourceCreationFailure)
        let commandQueue = try device.makeCommandQueue().orThrow(.resourceCreationFailure)
        let processor = Processor(device: device, completion: .commitAndWaitUntilCompleted, commandQueue: commandQueue)
        let content = self
        try processor.process(content)
    }
}
