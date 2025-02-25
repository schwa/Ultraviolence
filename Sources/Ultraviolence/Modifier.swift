import UltraviolenceSupport

// TODO: Unit test the shit out of this.

public protocol ElementModifier: Element {
    typealias Body = Element
    typealias Content = _ElementModifier_Content<Self>
    func body(content: Content) -> Body
}

//public extension ElementModifier where Body == Never {
//    func body(content: Content) -> Body {
//        unreachable()
//    }
//}

public struct _ElementModifier_Content <Content>: Element {
    internal let content: Content

    internal init(content: Content) {
        self.content = content
    }

    public var body: some Element {
        fatalError()
    }
}

// TODO: This is an internal detail.
public struct ModifiedContent <Content, Modifier>: Element where Content: Element, Modifier: ElementModifier {
    private let content: Content
    private let modifier: Modifier

    public init(content: Content, modifier: Modifier) {
        self.content = content
        self.modifier = modifier
    }

    public var body: some Element {
        let x = modifier.body(content: _ElementModifier_Content(content: modifier))
        return x
    }
}

public extension Element {
    func modifier<Modifier>(_ modifier: Modifier) -> some Element where Modifier: ElementModifier {
        ModifiedContent(content: self, modifier: modifier)
    }
}

// MARK: -

//public struct PassthroughModifier: ElementModifier {
//    public init() {
//    }
//
//    public func body(content: Content) -> some Element {
//        content
//    }
//}

public struct AnyModifier: ElementModifier {
    private let modify: (Content) -> Body

    init(_ modify: @escaping (Content) -> Body) {
        self.modify = modify
    }

    public func body(content: Content) -> Body {
        modify(content)
    }
}

