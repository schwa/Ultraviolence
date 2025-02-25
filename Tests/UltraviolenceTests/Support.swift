@testable import Ultraviolence

extension Graph {
    func element<V>(at path: [Int], type: V.Type) -> V {
        var node: Node = root
        for index in path {
            node = node.children[index]
        }
        return node.element as! V
    }
}
