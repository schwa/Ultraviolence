public struct EmptyPass: RenderPass {
    public typealias Body = Never

    public func visit(_ visitor: inout Visitor) throws {
        // This line intentionally left blank.
    }
}
