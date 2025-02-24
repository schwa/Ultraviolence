import CoreGraphics
import Metal
import UltraviolenceSupport

internal extension Graph {
    @MainActor
    internal func process() throws {
        logger?.log("\(type(of: self)).\(#function) enter.")
        defer {
            logger?.log("\(type(of: self)).\(#function) exit.")
        }
        var enviromentStack: [UVEnvironmentValues] = [rootEnvironment]
        try visit { node in
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
