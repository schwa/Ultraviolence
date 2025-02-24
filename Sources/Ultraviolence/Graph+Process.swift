import CoreGraphics
import Metal
import UltraviolenceSupport

internal extension Graph {
    @MainActor
    internal func process() throws {
        try process { element, node, environment in
            try element.workloadEnter(node, environment: &environment)
        } exit: { element, node, environment in
            try element.workloadExit(node, environment: environment)
        }
    }

    @MainActor
    internal func process(enter: (any BodylessElement, Node, inout UVEnvironmentValues) throws -> Void, exit: (any BodylessElement, Node, inout UVEnvironmentValues) throws -> Void) throws {
        logger?.log("\(type(of: self)).\(#function) enter.")
        defer {
            logger?.log("\(type(of: self)).\(#function) exit.")
        }
        var enviromentStack: [UVEnvironmentValues] = [.init()]
        try visit { node in
            var environment = node.environmentValues
            guard let last = enviromentStack.last else {
                preconditionFailure("Stack underflow")
            }
            environment.merge(last)
            logger?.log("\(String(repeating: "􀄫", count: enviromentStack.count)) '\(node.shortDescription)._enter()'")
            if let body = node.element as? any BodylessElement {
                try enter(body, node, &environment)
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
                try exit(body, node, &environment)
            }
        }
    }
}
