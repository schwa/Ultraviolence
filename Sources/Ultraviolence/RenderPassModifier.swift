import Metal

// TODO: Make into actual Modifier.
internal struct RenderPassModifier<Content>: Element, BodylessContentElement where Content: Element {
    @UVEnvironment(\.renderPassDescriptor)
    var renderPassDescriptor

    var content: Content
    var modify: (MTLRenderPassDescriptor) -> Void

    func body(content: Content) -> some Element {
        content
    }

    func setupEnter(_ node: Node) throws {
        if let renderPassDescriptor {
            modify(renderPassDescriptor)
        }
    }
}

public extension Element {
    func renderPassModifier(_ modify: @escaping (MTLRenderPassDescriptor) -> Void) -> some Element {
        RenderPassModifier(content: self, modify: modify)
    }
}
