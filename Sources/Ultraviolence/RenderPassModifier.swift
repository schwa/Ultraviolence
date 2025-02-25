import Metal

internal struct RenderPassModifier<Content>: Element, BodylessContentElement where Content: Element {
    @UVEnvironment(\.renderPassDescriptor)
    var renderPassDescriptor

    var content: Content
    var modify: (MTLRenderPassDescriptor) -> Void

    func body(content: Content) -> some Element {
        content
    }
}

public extension Element {
    func renderPassModifier(_ modify: @escaping (MTLRenderPassDescriptor) -> Void) -> some Element {
        RenderPassModifier(content: self, modify: modify)
    }
}
