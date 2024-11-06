import Metal

public struct Render <Content>: RenderPass where Content: RenderPass {
    public typealias Body = Never

    var content: Content

    public init(@RenderPassBuilder content: () throws -> Content) rethrows {
        self.content = try content()
    }

    public func visit(_ visitor: inout Visitor) throws {
        try visitor.log(node: self) { visitor in
            let commandBuffer = try visitor.commandBuffer.orThrow(.missingEnvironment(".commandBuffer"))
            let renderPassDescriptor = try visitor.renderPassDescriptor.orThrow(.missingEnvironment(".renderPassDescriptor"))

            try commandBuffer.withRenderCommandEncoder(descriptor: renderPassDescriptor, label: "􀐛Render.encoder") { encoder in
                visitor.insert(.renderCommandEncoder(encoder))
                let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
                if let colorTexture0 = renderPassDescriptor.colorAttachments[0].texture {
                    renderPipelineDescriptor.colorAttachments[0].pixelFormat = colorTexture0.pixelFormat
                }
                if let depthTexture = renderPassDescriptor.depthAttachment.texture {
                    renderPipelineDescriptor.depthAttachmentPixelFormat = depthTexture.pixelFormat
                }
                visitor.insert(.renderPipelineDescriptor(renderPipelineDescriptor))
                try content.visit(&visitor)
            }
        }
    }
}
