import Metal

public struct RenderPass <Content>: Element, BodylessElement, BodylessContentElement where Content: Element {
    var content: Content

    public init(@ElementBuilder content: () throws -> Content) throws {
        self.content = try content()
    }

    func system_setupEnter(_ node: NeoNode) throws {
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        node.environmentValues.renderPipelineDescriptor = renderPipelineDescriptor
    }

    func system_workloadEnter(_ node: NeoNode) throws {
        let commandBuffer = try node.environmentValues.commandBuffer.orThrow(.missingEnvironment(\.commandBuffer))
        let renderPassDescriptor = try node.environmentValues.renderPassDescriptor.orThrow(.missingEnvironment(\.renderPassDescriptor))
        let renderCommandEncoder = try commandBuffer._makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        node.environmentValues.renderCommandEncoder = renderCommandEncoder
    }

    func system_workloadExit(_ node: NeoNode) throws {
        let renderCommandEncoder = try node.environmentValues.renderCommandEncoder.orThrow(.missingEnvironment(\.renderCommandEncoder))
        renderCommandEncoder.endEncoding()
        node.environmentValues.renderCommandEncoder = nil
    }
}
