import CoreGraphics
import Metal
import UltraviolenceSupport

internal struct Processor {
    var device: MTLDevice
    var completion: MTLCommandQueueCompletion
    var commandQueue: MTLCommandQueue

    @MainActor
    func process<Content>(_ content: Content, capture: Bool = false) throws where Content: Element {
        logger?.log("\(type(of: self)).\(#function) enter.")
        defer {
            logger?.log("\(type(of: self)).\(#function) exit.")
        }
        let content = content
            .environment(\.device, device)

        let graph = try Graph(content: content)
        try MTLCaptureManager.shared().with(enabled: capture) {
            try commandQueue.withCommandBuffer(logState: nil, completion: completion, label: "TODO", debugGroup: "CommandBuffer") { commandBuffer in
                var rootEnvironment = UVEnvironmentValues()
                rootEnvironment.commandBuffer = commandBuffer
                rootEnvironment.commandQueue = commandQueue
                try _process(graph: graph, rootEnvironment: rootEnvironment)
            }
        }
    }

    @MainActor
    func _process(graph: Graph, rootEnvironment: UVEnvironmentValues, log: Bool = true) throws {
        logger?.log("\(type(of: self)).\(#function) enter.")
        defer {
            logger?.log("\(type(of: self)).\(#function) exit.")
        }
        let logger = log ? logger : nil
        var enviromentStack: [UVEnvironmentValues] = [rootEnvironment]
        try graph.visit { _, _ in
            // This line intentionally left blank.
        }
        enter: { node in
            var environment = node.environmentValues
            guard let last = enviromentStack.last else {
                preconditionFailure("Stack underflow")
            }
            environment.merge(last)
            logger?.log("\(String(repeating: "􀄫", count: enviromentStack.count)) '\(node.shortDescription)._enter()'")
            if let body = node.element as? any BodylessElement {
                try body._enter(node, environment: &environment)
            }
            enviromentStack.append(environment)
        }
        exit: { node in
            var environment = node.environmentValues
            guard let last = enviromentStack.last else {
                preconditionFailure("Stack underflow")
            }
            environment.merge(last)
            enviromentStack.removeLast()

            logger?.log("\(String(repeating: "􀄪", count: enviromentStack.count)) '\(node.shortDescription)._exit()'")
            if let body = node.element as? any BodylessElement {
                try body._exit(node, environment: environment)
            }
        }
    }
}
