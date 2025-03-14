// TODO: #106 this is going to be complex.
// TODO: #107 Compare ids to see if they've changed in expandNode.

public struct ForEach <Data, ID, Content>: Element where Data: RandomAccessCollection, ID: Hashable, Content: Element {
    @UVState
    var ids: [ID]

    var data: Data
    var content: (Data.Element) throws -> Content
}

public extension ForEach {
    init(_ data: Data, @ElementBuilder content: @escaping (Data.Element) throws -> Content) where Data: Collection, Data.Element: Identifiable, Data.Element.ID == ID {
        self.ids = data.map(\.id)
        self.data = data
        self.content = content
        assert(Set(self.ids).count == self.ids.count)
    }

    init(_ data: Data, id: KeyPath<Data.Element, ID>, @ElementBuilder content: @escaping (Data.Element) throws -> Content) where Data: Collection {
        self.ids = data.map { $0[keyPath: id] }
        self.data = data
        self.content = content
        assert(Set(self.ids).count == self.ids.count)
    }
}

extension ForEach: BodylessElement {
    internal func _expandNode(_ node: Node, context: ExpansionContext) throws {
        let graph = try node.graph.orThrow(.noCurrentGraph)
        var index = 0

        for datum in data {
            if node.children.count <= index {
                node.children.append(graph.makeNode())
            }

            let content = try content(datum)
            try content.expandNode(node.children[index], context: context.deeper())
            index += 1
        }
    }
}
