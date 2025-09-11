public struct _ConditionalContent<TrueContent, FalseContent>: Element, BodylessElement where TrueContent: Element, FalseContent: Element {
    let first: TrueContent?
    let second: FalseContent?

    init(first: TrueContent) {
        self.first = first
        self.second = nil
    }

    init(second: FalseContent) {
        self.first = nil
        self.second = second
    }

    func visitChildrenBodyless(_ visit: (any Element) throws -> Void) throws {
        if let first {
            try visit(first)
        }
        else if let second {
            try visit(second)
        }
    }
}
