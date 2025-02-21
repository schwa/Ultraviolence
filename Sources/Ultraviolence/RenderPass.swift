import Metal

public struct RenderPass <Content>: Element, BodylessElement where Content: Element {
    var content: Content

    public init(content: () throws -> Content) throws {
        self.content = try content()
    }

    func _expandNode(_ node: Node) throws {
        // TODO: Move into BodylessRenderPass
        guard let graph = node.graph else {
            preconditionFailure("Cannot build node tree without a graph.")
        }
        if node.children.isEmpty {
            node.children.append(graph.makeNode())
        }
        try content.expandNode(node.children[0])
    }

    func _enter(_ node: Node, environment: inout EnvironmentValues) throws {
        let commandBuffer = try environment.commandBuffer.orThrow(.missingEnvironment(\.commandBuffer))
        commandBuffer.pushDebugGroup("RENDER PASS")
        let renderPassDescriptor = try environment.renderPassDescriptor.orThrow(.missingEnvironment(\.renderPassDescriptor))
        logger?.log("Render.\(#function) makeRenderCommandEncoder")
        let renderCommandEncoder = try commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor).orThrow(.resourceCreationFailure)
        environment.renderCommandEncoder = renderCommandEncoder
    }

    func _exit(_ node: Node, environment: EnvironmentValues) throws {
        let commandBuffer = try environment.commandBuffer.orThrow(.missingEnvironment(\.commandBuffer))
        let renderCommandEncoder = try environment.renderCommandEncoder.orThrow(.missingEnvironment(\.renderCommandEncoder))
        renderCommandEncoder.endEncoding()
        logger?.log("Render.\(#function) endEncoding")
        commandBuffer.popDebugGroup()
    }
}
