import CoreGraphics
import Metal

internal extension Graph {
    @MainActor
    func processSetup() throws {
        try process { element, node in
            try element.setupEnter(node)
        } exit: { element, node in
            try element.setupExit(node)
        }
    }

    @MainActor
    func processWorkload() throws {
        try process { element, node in
            try element.workloadEnter(node)
        } exit: { element, node in
            try element.workloadExit(node)
        }
    }

    @MainActor
    func process(enter: (any BodylessElement, Node) throws -> Void, exit: (any BodylessElement, Node) throws -> Void) throws {
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
