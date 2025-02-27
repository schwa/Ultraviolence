import Metal
import UltraviolenceSupport

public extension Element {
    @MainActor
    func run() throws {
        // TODO: This has surprisingly little to do with compute. It's basically the same as offscreen renderer. https://github.com/schwa/Ultraviolence/issues/27
        let device = _MTLCreateSystemDefaultDevice()
        let commandQueue = try device._makeCommandQueue()

        let content = CommandBufferElement(completion: .commitAndWaitUntilCompleted) {
            self
        }
        .environment(\.commandQueue, commandQueue)
        .environment(\.device, device)

        let graph = try Graph(content: content)
        try graph.processSetup()
        try graph.processWorkload()
    }
}
