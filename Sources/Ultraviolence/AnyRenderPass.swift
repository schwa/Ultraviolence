// TODO: This seems useless.
public struct AnyRenderPass: RenderPass {
    public typealias Body = Never

    var render: (inout Visitor) throws -> Void

    init(render: @escaping (inout Visitor) throws -> Void) {
        self.render = render
    }

    public func visit(_ visitor: inout Visitor) throws {
        try render(&visitor)
    }
}
