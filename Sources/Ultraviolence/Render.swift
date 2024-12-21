import Metal

// TODO: this should really be called renderpass
public struct Render <Content>: RenderPass, BodylessRenderPass where Content: RenderPass {
    var content: Content

    public init(content: () -> Content) {
        self.content = content()
    }

    func _expandNode(_ node: Node) throws {
        // TODO: Move into BodylessRenderPass
        guard let graph = node.graph else {
            fatalError("Cannot build node tree without a graph.")
        }
        if node.children.isEmpty {
            node.children.append(graph.makeNode())
        }
        try content.expandNode(node.children[0])
    }

    func _enter(_ node: Node, environment: inout EnvironmentValues) throws {
        let commandBuffer = try environment.commandBuffer.orThrow(.missingEnvironment("commandBuffer"))
        let renderPassDescriptor = try environment.renderPassDescriptor.orThrow(.missingEnvironment("renderPassDescriptor"))
        logger?.log("Render.\(#function) makeRenderCommandEncoder")
        let renderCommandEncoder = try commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor).orThrow(.resourceCreationFailure)
        environment.renderCommandEncoder = renderCommandEncoder
    }

    func _exit(_ node: Node, environment: EnvironmentValues) throws {
        let renderCommandEncoder = try environment.renderCommandEncoder.orThrow(.missingEnvironment("renderCommandEncoder"))
        renderCommandEncoder.endEncoding()
        logger?.log("Render.\(#function) endEncoding")
    }
}
