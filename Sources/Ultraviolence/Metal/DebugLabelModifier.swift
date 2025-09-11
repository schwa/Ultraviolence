// TODO: System
//internal struct DebugLabelModifier <Content>: Element, BodylessElement, BodylessContentElement where Content: Element {
//    let debugLabel: String
//    let content: Content
//
//    init(_ debugLabel: String, content: Content) {
//        self.debugLabel = debugLabel
//        self.content = content
//    }
//
//    func expandIntoNode(_ node: Node, context: ExpansionContext) throws {
//        // TODO: #95 We don't expand a new node - instead of we create expand our child's node. This is subtle and confusing and we really need to clean up all this:
//        //    self._expandNode() vs content.expandNode vs .......
//        //    a lot more nodes COULD work this way.
//        node.debugLabel = debugLabel
//        try content.expandNode(node, context: context.deeper())
//    }
//}
//
//public extension Element {
//    func debugLabel(_ debugLabel: String) -> some Element {
//        DebugLabelModifier(debugLabel, content: self)
//    }
//}
