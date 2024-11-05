public struct TuplePass <each T: RenderPass>: RenderPass {
    public typealias Body = Never

    var value: (repeat each T)

    public init(_ value: repeat each T) {
        self.value = (repeat each value)
    }

    public func visit(_ visitor: inout Visitor) throws {
        try visitor.log(label: "TuplePass.\(#function).") { visitor in
            for element in repeat (each value) {
                try element.visit(&visitor)
            }
        }
    }
}
