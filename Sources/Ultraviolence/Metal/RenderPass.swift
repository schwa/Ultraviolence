import Metal

public struct RenderPass <Content>: Element, BodylessElement, BodylessContentElement where Content: Element {
    private let label: String?
    internal let content: Content

    public init(label: String? = nil, @ElementBuilder content: () throws -> Content) throws {
        self.label = label
        self.content = try content()
    }

    func setupEnter(_ node: Node) throws {
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        node.environmentValues.renderPipelineDescriptor = renderPipelineDescriptor
    }

    func workloadEnter(_ node: Node) throws {
        logger?.verbose?.info("Start render pass: \(label ?? "<unlabeled>") (\(node.element.internalDescription))")
        let commandBuffer = try node.environmentValues.commandBuffer.orThrow(.missingEnvironment(\.commandBuffer))
        let renderPassDescriptor = try node.environmentValues.renderPassDescriptor.orThrow(.missingEnvironment(\.renderPassDescriptor))
        let renderCommandEncoder = try commandBuffer._makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        if let label {
            renderCommandEncoder.label = label
        }
        node.environmentValues.renderCommandEncoder = renderCommandEncoder
    }

    func workloadExit(_ node: Node) throws {
        let renderCommandEncoder = try node.environmentValues.renderCommandEncoder.orThrow(.missingEnvironment(\.renderCommandEncoder))
        renderCommandEncoder.endEncoding()
        node.environmentValues.renderCommandEncoder = nil
        logger?.verbose?.info("Ending render pass: \(label ?? "<unlabeled>") (\(node.element.internalDescription))")

    }
}
