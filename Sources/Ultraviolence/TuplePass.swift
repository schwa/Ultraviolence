public struct TuplePass <each T: RenderPass>: RenderPass {
    public typealias Body = Never

    var value: (repeat each T)

    public init(_ value: repeat each T) {
        self.value = (repeat each value)
    }

    public func visit(visitor: inout Visitor) throws {
        try visitor.log(node: self) { visitor in
            for element in repeat (each value) {
                try element.visit(visitor: &visitor)
            }
        }
    }
}
