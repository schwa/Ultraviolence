// TODO: Name overlaps with SwiftUI.Group. Consider renaming.
public struct Group <Content>: Element where Content: Element {
    public typealias Body = Never

    internal let content: Content

    public init(@ElementBuilder content: () throws -> Content) throws {
        self.content = try content()
    }
}

extension Group: BodylessElement, BodylessContentElement {
}
