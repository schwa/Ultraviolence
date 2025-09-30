import Metal

// TODO: #30 Make into actual Modifier.
// TODO: #99 is this actually necessary? Elements just use an environment?
public struct RenderPipelineDescriptorModifier<Content>: Element where Content: Element {
    @UVEnvironment(\.renderPipelineDescriptor)
    var renderPipelineDescriptor

    var content: Content
    var modify: (MTLRenderPipelineDescriptor) -> Void

    // TODO: #72 this is pretty bad. We're only modifying it for workload NOT setup. And we're modifying it globally - even for elements further up the stack.
    public var body: some Element {
        get throws {
            content.environment(\.renderPipelineDescriptor, try modifiedRenderPipelineDescriptor())
        }
    }

    func modifiedRenderPipelineDescriptor() throws -> MTLRenderPipelineDescriptor {
        let renderPipelineDescriptor = renderPipelineDescriptor.orFatalError("Missing render pipeline descriptor")
        let copy = (renderPipelineDescriptor.copy() as? MTLRenderPipelineDescriptor).orFatalError("Failed to copy render pipeline descriptor")
        modify(copy)
        return copy
    }
}

public extension Element {
    func renderPipelineDescriptorModifier(_ modify: @escaping (MTLRenderPipelineDescriptor) -> Void) -> some Element {
        RenderPipelineDescriptorModifier(content: self, modify: modify)
    }
}
