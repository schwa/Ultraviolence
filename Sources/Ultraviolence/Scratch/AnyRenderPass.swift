// TODO: This seems useless.
@available(*, deprecated, message: "Dont use (yet?)")
public struct AnyRenderPass: RenderPass {
    public typealias Body = Never

    var render: (inout Visitor) throws -> Void

    init(render: @escaping (inout Visitor) throws -> Void) {
        self.render = render
    }

    public func visit(visitor: inout Visitor) throws {
        try visitor.log(node: self) { visitor in
            try render(&visitor)
        }
    }
}
