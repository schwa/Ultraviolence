public struct Button: RenderPass, BodylessRenderPass {
    public typealias Body = Never

    public private(set) var title: String
    public private(set) var action: () -> Void

    public init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    func _expandNode(_ node: Node) {
        // todo create a UIButton
    }
}
