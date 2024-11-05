import Metal

public struct Render <Content>: RenderPass where Content: RenderPass {
    public typealias Body = Never

    var content: Content

    public init(@RenderPassBuilder content: () throws -> Content) rethrows {
        self.content = try content()
    }

    public func visit(_ visitor: inout Visitor) throws {
        logger?.log("ENTER: Render.\(#function).")
        defer {
            logger?.log("EXIT:  Render.\(#function).")
        }
        let commandQueue = try visitor.commandQueue.orThrow(.missingEnvironment(".commandQueue"))
        return try commandQueue.withCommandBuffer(completion: .commitAndWaitUntilCompleted, label: "􀐛Renderer.commandBuffer", debugGroup: "􀯕Renderer.render()") { commandBuffer in
            let renderPassDescriptor = try visitor.renderPassDescriptor.orThrow(.missingEnvironment(".renderPassDescriptor"))
            try commandBuffer.withRenderCommandEncoder(descriptor: renderPassDescriptor, label: "􀐛Renderer.encoder") { encoder in
                let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
                if let colorTexture0 = renderPassDescriptor.colorAttachments[0].texture {
                    renderPipelineDescriptor.colorAttachments[0].pixelFormat = colorTexture0.pixelFormat
                }
                if let depthTexture = renderPassDescriptor.depthAttachment.texture {
                    renderPipelineDescriptor.depthAttachmentPixelFormat = depthTexture.pixelFormat
                }
                let device = commandQueue.device
                var visitor = Visitor(device: device)
                try visitor.with([.commandBuffer(commandBuffer), .renderEncoder(encoder), .renderPipelineDescriptor(renderPipelineDescriptor)]) { visitor in
                    try content.visit(&visitor)
                }
            }
        }
    }
}
