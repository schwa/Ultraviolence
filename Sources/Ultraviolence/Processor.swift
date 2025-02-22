import CoreGraphics
import Metal
import UltraviolenceSupport

// TODO: This is very generically named.
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
        let content = CommandBufferElement(completion: completion) {
            content
        }
        .environment(\.device, device)

        let graph = try Graph(content: content)
        try MTLCaptureManager.shared().with(enabled: capture) {
            var rootEnvironment = UVEnvironmentValues()
            rootEnvironment.commandQueue = commandQueue
            try process(graph: graph, rootEnvironment: rootEnvironment)
        }
    }

    @MainActor
    private func process(graph: Graph, rootEnvironment: UVEnvironmentValues) throws {
        logger?.log("\(type(of: self)).\(#function) enter.")
        defer {
            logger?.log("\(type(of: self)).\(#function) exit.")
        }
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

// TODO: Rename
internal protocol FoobarElement: BodylessElement {
    associatedtype Content: Element

    var content: Content { get }
}

extension FoobarElement {
    func _expandNode(_ node: Node, depth: Int) throws {
        guard let graph = node.graph else {
            preconditionFailure("Cannot build node tree without a graph.")
        }
        if node.children.isEmpty {
            node.children.append(graph.makeNode())
        }
        try content.expandNode(node.children[0], depth: depth + 1)
    }
}

public struct CommandBufferElement <Content>: Element, FoobarElement where Content: Element {
    var completion: MTLCommandQueueCompletion
    var content: Content

    init(completion: MTLCommandQueueCompletion, @ElementBuilder content: () throws -> Content) rethrows {
        self.completion = completion
        self.content = try content()
    }



    func _enter(_ node: Node, environment: inout UVEnvironmentValues) throws {
        let device = try environment.device.orThrow(.missingEnvironment(\.commandBuffer))
        let commandQueue = try environment.commandQueue.orThrow(.missingEnvironment(\.commandBuffer))
        let commandBufferDescriptor = MTLCommandBufferDescriptor()
        let commandBuffer = try commandQueue.makeCommandBuffer(descriptor: commandBufferDescriptor).orThrow(.resourceCreationFailure)
        environment.commandBuffer = commandBuffer
    }

    func _exit(_ node: Node, environment: UVEnvironmentValues) throws {
        let commandBuffer = try environment.commandBuffer.orThrow(.missingEnvironment(\.commandBuffer))
        switch completion {
        case .none:
            break
        case .commit:
            commandBuffer.commit()
        case .commitAndWaitUntilCompleted:
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
        }
    }
}
