import Metal

// TODO; Currently won't work because Issue #30
public struct RenderPassModifier: ElementModifier {
    @UVEnvironment(\.renderPassDescriptor)
    var renderPassDescriptor

    var modify: (MTLRenderPassDescriptor) -> Void

    public init(_ modify: @escaping (MTLRenderPassDescriptor) -> Void) {
        self.renderPassDescriptor = renderPassDescriptor
        self.modify = modify
    }

    public func body(content: Content) -> some Element {
        content
    }
}

public extension Element {
    func renderPassModifier(_ modify: @escaping (MTLRenderPassDescriptor) -> Void) -> some Element {
        modifier(RenderPassModifier(modify: modify))
    }
}
