import Metal

// TODO: #30 Make into actual Modifier.
internal struct RenderPassDescriptorModifier<Content>: Element, BodylessContentElement where Content: Element {
    @UVEnvironment(\.renderPassDescriptor)
    var renderPassDescriptor

    var content: Content
    var modify: (MTLRenderPassDescriptor) -> Void

    func body(content: Content) -> some Element {
        content
    }

    func workloadEnter(_ node: Node) throws {
        if let renderPassDescriptor {
            modify(renderPassDescriptor)
        }
    }
}

public extension Element {
    func renderPassDescriptorModifier(_ modify: @escaping (MTLRenderPassDescriptor) -> Void) -> some Element {
        RenderPassDescriptorModifier(content: self, modify: modify)
    }
}
