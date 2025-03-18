import CoreGraphics
import Metal

public extension Graph {
    @MainActor
    func processSetup() throws {
        try signposter?.withIntervalSignpost("Graph.processSetup()") {
            try process { element, node in
                try element.setupEnter(node)
            } exit: { element, node in
                try element.setupExit(node)
            }
        }
    }

    @MainActor
    func processWorkload() throws {
        try signposter?.withIntervalSignpost("Graph.processWorkload()") {
            try process { element, node in
                try element.workloadEnter(node)
            } exit: { element, node in
                try element.workloadExit(node)
            }
        }
    }
}

internal extension Graph {
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
