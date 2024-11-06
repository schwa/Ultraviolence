public struct EmptyPass: RenderPass {
    public typealias Body = Never

    public func visit(visitor: inout Visitor) throws {
        try visitor.log(node: self) { _ in
            // This line intentionally left blank.
        }
    }
}
