import CoreGraphics
import Metal
import UltraviolenceSupport

internal struct Processor {
    var device: MTLDevice
    var completion: MTLCommandQueueCompletion
    var commandQueue: MTLCommandQueue

    @MainActor
    func render<Content>(_ content: Content, capture: Bool = false) throws where Content: Element {
        logger?.log("\(type(of: self)).\(#function) enter.")
        defer {
            logger?.log("\(type(of: self)).\(#function) exit.")
        }
        let content = content
            .environment(\.device, device)

        let graph = try Graph(content: content)
        try graph.rebuildIfNeeded()

        try MTLCaptureManager.shared().with(enabled: capture) {
            try commandQueue.withCommandBuffer(logState: nil, completion: completion, label: "TODO", debugGroup: "CommandBuffer") { commandBuffer in
                var rootEnvironment = EnvironmentValues()
                rootEnvironment.device = device
                rootEnvironment.commandBuffer = commandBuffer
                rootEnvironment.commandQueue = commandQueue
                try graph._process(rootEnvironment: rootEnvironment)
            }
        }
    }
}
