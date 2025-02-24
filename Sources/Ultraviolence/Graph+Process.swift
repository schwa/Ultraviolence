import CoreGraphics
import Metal
import UltraviolenceSupport

internal extension Graph {
    @MainActor
    internal func processSetup() throws {
        try process { element, node in
            try element.setupEnter(node)
        } exit: { element, node in
            try element.setupExit(node)
        }
    }

    @MainActor
    internal func processWorkload() throws {
        try process { element, node in
            try element.workloadEnter(node)
        } exit: { element, node in
            try element.workloadExit(node)
        }
    }

    @MainActor
    internal func process(enter: (any BodylessElement, Node) throws -> Void, exit: (any BodylessElement, Node) throws -> Void) throws {
        logger?.log("\(type(of: self)).\(#function) enter.")
        defer {
            logger?.log("\(type(of: self)).\(#function) exit.")
        }
        try visit { node in
            if let body = node.element as? any BodylessElement {
                try enter(body, node)
            }
        }
        exit: { node in
            if let body = node.element as? any BodylessElement {
                try exit(body, node)
            }
        }
    }
}
