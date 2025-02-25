import UltraviolenceSupport

// TODO: Unit test the shit out of this.

public protocol ElementModifier: Element {
    typealias Body = Never
    typealias Content = _ElementModifier_Content<Self>
    func body(content: Content) -> Body
}

// TODO: We can just rely on Never conforming to Element.
public extension ElementModifier where Body == Never {
    func body(content: Content) -> Body {
        unreachable()
    }
}

public struct _ElementModifier_Content <Content>: Element where Content: Element {
    private let content: Content

    internal init(content: Content) {
        self.content = content
    }

    public var body: some Element {
        content
    }
}

internal struct ModifiedContent <Content, Modifier>: Element where Content: Element, Modifier: ElementModifier {
    private let content: Content
    private let modifier: Modifier

    internal init(content: Content, modifier: Modifier) {
        self.content = content
        self.modifier = modifier
    }

    internal var body: some Element {
        modifier.body(content: _ElementModifier_Content(content: modifier))
    }
}

public extension Element {
    func modifier<Modifier>(_ modifier: Modifier) -> some Element where Modifier: ElementModifier {
        ModifiedContent(content: self, modifier: modifier)
    }
}

public struct PassthroughModifier: ElementModifier {
    public init() {
    }

    public func body(content: Content) -> some Element {
        content
    }
}
