import Metal

// TODO: this should really be called renderpass
public struct Render <Content>: RenderPass, BodylessRenderPass where Content: RenderPass {
    var content: Content

    public init(content: () -> Content) {
        self.content = content()
    }

    func _expandNode(_ node: Node) throws {
        // TODO: Move into BodylessRenderPass
        guard let graph = node.graph else {
            fatalError("Cannot build node tree without a graph.")
        }
        if node.children.isEmpty {
            node.children.append(graph.makeNode())
        }
        try content.expandNode(node.children[0])
    }
}
