@resultBuilder
@MainActor
// swiftlint:disable:next convenience_type
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

    // TODO: #47 Flesh this out (follow ViewBuilder for more). TODO: Still requires unit tests.
    /// Produces content for a conditional statement in a multi-statement closure when the condition is true.
    public static func buildEither<TrueContent, FalseContent>(first: TrueContent) -> _ConditionalContent<TrueContent, FalseContent> where TrueContent: Element, FalseContent: Element {
        _ConditionalContent(first: first)
    }

    /// Produces content for a conditional statement in a multi-statement closure when the condition is false.
    public static func buildEither<TrueContent, FalseContent>(second: FalseContent) -> _ConditionalContent<TrueContent, FalseContent> where TrueContent: Element, FalseContent: Element {
        _ConditionalContent(second: second)
    }

    public static func buildLimitedAvailability<Content>(_ content: Content) -> AnyElement where Content: Element {
        AnyElement(content)
    }
}
