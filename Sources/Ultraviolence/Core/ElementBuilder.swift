@resultBuilder
@MainActor
public struct ElementBuilder {
    public static func buildBlock<V: Element>(_ content: V) -> V {
        content
    }

    public static func buildBlock() -> EmptyElement {
        EmptyElement()
    }

    public static func buildBlock<each Content>(_ content: repeat each Content) -> TupleElement<repeat each Content> where repeat each Content: Element {
        TupleElement(repeat each content)
    }

    public static func buildOptional<Content>(_ content: Content?) -> some Element where Content: Element {
        content
    }

    // TODO: #47 Flesh this out (follow ViewBuilder for more)
}
