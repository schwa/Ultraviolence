import Metal

public struct RenderPass <Content>: Element, BodylessElement, BodylessContentElement where Content: Element {
    var content: Content

    public init(@ElementBuilder content: () throws -> Content) throws {
        self.content = try content()
    }

    func setupEnter(_ node: Node) throws {
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        node.environmentValues.renderPipelineDescriptor = renderPipelineDescriptor
    }

    func workloadEnter(_ node: Node) throws {
        let commandBuffer = try node.environmentValues.commandBuffer.orThrow(.missingEnvironment(\.commandBuffer))
        let renderPassDescriptor = try node.environmentValues.renderPassDescriptor.orThrow(.missingEnvironment(\.renderPassDescriptor))
        let renderCommandEncoder = try commandBuffer._makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        node.environmentValues.renderCommandEncoder = renderCommandEncoder
    }

    func workloadExit(_ node: Node) throws {
        let renderCommandEncoder = try node.environmentValues.renderCommandEncoder.orThrow(.missingEnvironment(\.renderCommandEncoder))
        renderCommandEncoder.endEncoding()
        node.environmentValues.renderCommandEncoder = nil
    }
}
