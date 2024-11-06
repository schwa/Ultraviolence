public struct Chain <Content: RenderPass>: RenderPass where Content: RenderPass {
    var content: Content

    public init(@RenderPassBuilder content: () throws -> Content) rethrows {
        self.content = try content()
    }

    public var body: some RenderPass {
        content
    }
}
