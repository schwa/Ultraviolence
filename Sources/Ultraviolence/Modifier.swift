import UltraviolenceSupport

public protocol ElementModifier {
    // TODO: Remove reliance on AnyElement?
    typealias Content = AnyElement
    associatedtype Body: Element

    @MainActor
    func body(content: Content) -> Body
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
        modifier.body(content: AnyElement(content))
    }
}

public extension Element {
    func modifier<Modifier>(_ modifier: Modifier) -> some Element where Modifier: ElementModifier {
        ModifiedContent(content: self, modifier: modifier)
    }
}

// MARK: -

public struct PassthroughModifier: ElementModifier {
    public init() {
    }

    @MainActor
    public func body(content: Content) -> some Element {
        content
    }
}

// TODO: Type system is not letting something as simple as this.
//public struct AnyModifier: ElementModifier {
//    private let modify: (Content) -> Body
//
//    @MainActor
//    public func body(content: Content) -> Body {
//        modify(content)
//    }
//}

