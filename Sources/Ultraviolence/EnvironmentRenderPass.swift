public struct EnvironmentRenderPass <Content>: RenderPass where Content: RenderPass {
    public typealias Body = Never

    var environment: [VisitorState]
    var content: Content

    public init(environment: [VisitorState], content: () -> Content) {
        self.environment = environment
        self.content = content()
    }

    public func visit(_ visitor: inout Visitor) throws {
        try visitor.with(environment) { visitor in
            try content.visit(&visitor)
        }
    }
}
