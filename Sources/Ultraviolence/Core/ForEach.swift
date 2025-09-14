public struct ForEach <Data, ID, Content>: Element where Data: RandomAccessCollection, ID: Hashable, Content: Element {
    // TODO: #107 Compare ids to see if they've changed in expandNode
    //    @UVState
    //    var ids: [ID]

    var data: Data
    var content: (Data.Element) throws -> Content
}

public extension ForEach {
    init(_ data: Data, @ElementBuilder content: @escaping (Data.Element) throws -> Content) where Data: Collection, Data.Element: Identifiable, Data.Element.ID == ID {
        //        self.ids = data.map(\.id)
        self.data = data
        self.content = content
    }

    init(_ data: Data, id: KeyPath<Data.Element, ID>, @ElementBuilder content: @escaping (Data.Element) throws -> Content) where Data: Collection {
        //        self.ids = data.map { $0[keyPath: id] }
        self.data = data
        self.content = content
    }
}

// TODO: #217 We're not using ids in the System StructuralIdentifier yet - need to implement proper ID tracking for ForEach elements
extension ForEach: BodylessElement {
    internal func visitChildrenBodyless(_ visit: (any Element) throws -> Void) throws {
        for datum in data {
            let child = try content(datum)
            try visit(child)
        }
    }
}
