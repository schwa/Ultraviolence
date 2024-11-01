public struct TuplePass <each T: RenderPass>: RenderPass {
    public typealias Body = Never
    var value: (repeat each T)

    public init(_ value: repeat each T) {
        self.value = (repeat each value)
    }

    public func render(_ state: inout RenderState) throws {
        for element in repeat (each value) {
            try element.render(&state)
        }
    }
}
