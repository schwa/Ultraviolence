import Metal
import UltraviolenceSupport

public extension Element {
    @MainActor
    func run() throws {
        // TODO: #27 This has surprisingly little to do with compute. It's basically the same as offscreen renderer.
        let device = _MTLCreateSystemDefaultDevice()
        let commandQueue = try device._makeCommandQueue()

        let content = CommandBufferElement(completion: .commitAndWaitUntilCompleted) {
            self
        }
        .environment(\.commandQueue, commandQueue)
        .environment(\.device, device)

        let graph = try NodeGraph(content: content)
        try graph.processSetup()
        try graph.processWorkload()
    }
}
