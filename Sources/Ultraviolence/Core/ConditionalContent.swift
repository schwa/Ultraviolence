public struct _ConditionalContent<TrueContent, FalseContent>: Element where TrueContent: Element, FalseContent: Element {
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

    internal func _expandNode(_ node: Node, context: ExpansionContext) throws {
        if let first {
            try first.expandNode(node, context: context.deeper())
        }
        else if let second {
            try second.expandNode(node, context: context.deeper())
        }
    }
}
