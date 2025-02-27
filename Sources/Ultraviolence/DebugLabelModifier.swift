internal struct DebugLabelModifier <Content>: Element, BodylessElement, BodylessContentElement where Content: Element {
    let debugLabel: String
    let content: Content

    init(_ debugLabel: String, content: Content) {
        self.debugLabel = debugLabel
        self.content = content
    }

    func _expandNode(_ node: Node, context: ExpansionContext) throws {
        try expandNodeHelper(node, context: context)
        node.debugLabel = debugLabel
    }
}

public extension Element {
    func debugLabel(_ debugLabel: String) -> some Element {
        DebugLabelModifier(debugLabel, content: self)
    }
}
