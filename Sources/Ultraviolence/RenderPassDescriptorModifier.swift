import Metal

// TODO: #30 Make into actual Modifier.
internal struct RenderPassDescriptorModifier<Content>: Element where Content: Element {
    @UVEnvironment(\.renderPassDescriptor)
    var renderPassDescriptor

    var content: Content
    var modify: (MTLRenderPassDescriptor) -> Void

    // TODO: #72 this is pretty bad. We're only modifying it for workload NOT setup. And we're modifying it globally - even for elements further up teh stack.
    var body: some Element {
        get throws {
            content.environment(\.renderPassDescriptor, try modifiedRenderPassDescriptor())
        }
    }

    func modifiedRenderPassDescriptor() throws -> MTLRenderPassDescriptor {
        let renderPassDescriptor = renderPassDescriptor.orFatalError()
        var copy = (renderPassDescriptor.copy() as? MTLRenderPassDescriptor).orFatalError()
        modify(copy)
        return copy
    }
}

public extension Element {
    func renderPassDescriptorModifier(_ modify: @escaping (MTLRenderPassDescriptor) -> Void) -> some Element {
        RenderPassDescriptorModifier(content: self, modify: modify)
    }
}
