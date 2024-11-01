@resultBuilder
public struct RenderPassBuilder {
    public static func buildBlock() -> some RenderPass {
        EmptyPass()
    }

    public static func buildBlock<Content>(_ content: Content) -> Content where Content: RenderPass {
        content
    }

    public static func buildBlock<each Content>(_ content: repeat each Content) -> TuplePass<repeat each Content> where repeat each Content: RenderPass {
        TuplePass(repeat each content)
    }

    public static func buildOptional<Content>(_ content: Content?) -> some RenderPass where Content: RenderPass {
        content
    }
}
