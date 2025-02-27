// TODO: #48 Name overlaps with SwiftUI.Group. Consider renaming. In practice this doesn't seem to be causing problems for me.
public struct Group <Content>: Element where Content: Element {
    public typealias Body = Never

    internal let content: Content

    public init(@ElementBuilder content: () throws -> Content) throws {
        self.content = try content()
    }
}

extension Group: BodylessElement, BodylessContentElement {
}
