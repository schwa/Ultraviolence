public struct AnyRenderPassModifier <Content>: RenderPass where Content: RenderPass {

    var content: Content
    var visit: (inout Visitor) throws -> Void

    public init(content: Content, visit: @escaping (inout Visitor) throws -> Void) {
        self.visit = visit
        self.content = content
    }

    public var body: some RenderPass {
        fatalError()
    }

    public func visit(_ visitor: inout Visitor) throws {
        try visit(&visitor)
        try content.visit(&visitor)
    }
}