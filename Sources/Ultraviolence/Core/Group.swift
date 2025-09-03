// NOTE: This is really just a "container" element.
public struct Group <Content>: Element where Content: Element {
    public typealias Body = Never

    internal let content: Content

    public init(@ElementBuilder content: () throws -> Content) throws {
        self.content = try content()
    }
}

extension Group: BodylessElement, BodylessContentElement {
}
