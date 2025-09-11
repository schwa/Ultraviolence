internal protocol BodylessContentElement: BodylessElement {
    associatedtype Content: Element

    var content: Content { get }
}

extension BodylessContentElement {
    func visitChildrenBodyless(_ visit: (any Element) throws -> Void) rethrows {
        try visit(content)
    }
}
