//import CoreGraphics
//import Metal
//import UltraviolenceSupport
//
//public extension NodeGraph {
//    @MainActor
//    func processSetup() throws {
//        try withIntervalSignpost(signposter, name: "NodeGraph.processSetup()") {
//            try process { element, node in
//                try element.setupEnter(node)
//            } exit: { element, node in
//                try element.setupExit(node)
//            }
//        }
//    }
//
//    @MainActor
//    func processWorkload() throws {
//        try withIntervalSignpost(signposter, name: "NodeGraph.processWorkload()") {
//            try process { element, node in
//                try element.workloadEnter(node)
//            } exit: { element, node in
//                try element.workloadExit(node)
//            }
//        }
//    }
//}
//
//internal extension NodeGraph {
//    @MainActor
//    func process(enter: (any BodylessElement, Node) throws -> Void, exit: (any BodylessElement, Node) throws -> Void) throws {
//        try visit { node in
//            if let body = node.element as? any BodylessElement {
//                try enter(body, node)
//            }
//        }
//        exit: { node in
//            if let body = node.element as? any BodylessElement {
//                try exit(body, node)
//            }
//        }
//    }
//}
