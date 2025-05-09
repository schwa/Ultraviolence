// TODO: #30 Stuff like @Environment/@State on modifiers won't work because.

@available(*, deprecated, message: "Incomplete: See issue https://github.com/schwa/ultraviolence/issues/30")
public protocol ElementModifier {
    typealias Content = AnyElement
    associatedtype Body: Element

    @MainActor
    func body(content: Content) -> Body
}

internal struct ModifiedContent <Content, Modifier>: Element where Content: Element, Modifier: ElementModifier {
    private let content: Content
    private let modifier: Modifier

    internal init(content: Content, modifier: Modifier) {
        self.content = content
        self.modifier = modifier
    }

    internal var body: some Element {
        modifier.body(content: AnyElement(content))
    }
}

@available(*, deprecated, message: "Incomplete: See issue https://github.com/schwa/ultraviolence/issues/30")
public extension Element {
    func modifier<Modifier>(_ modifier: Modifier) -> some Element where Modifier: ElementModifier {
        ModifiedContent(content: self, modifier: modifier)
    }
}

// MARK: -

@available(*, deprecated, message: "Incomplete: See issue https://github.com/schwa/ultraviolence/issues/30")
public struct PassthroughModifier: ElementModifier {
    public init() {
        // This line intentionally left blank.
    }

    @MainActor
    public func body(content: Content) -> some Element {
        content
    }
}

// TODO: #96 Type system is not letting something as simple as this.
// public struct AnyModifier: ElementModifier {
//    private let modify: (Content) -> Body
//
//    @MainActor
//    public func body(content: Content) -> Body {
//        modify(content)
//    }
// }
