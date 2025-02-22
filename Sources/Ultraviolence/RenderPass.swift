import Metal

public struct RenderPass <Content>: Element, BodylessElement where Content: Element {
    var content: Content

    public init(@ElementBuilder content: () throws -> Content) throws {
        self.content = try content()
    }

    func _expandNode(_ node: Node, depth: Int) throws {
        guard let graph = node.graph else {
            preconditionFailure("Cannot build node tree without a graph.")
        }
        if node.children.isEmpty {
            node.children.append(graph.makeNode())
        }
        try content.expandNode(node.children[0], depth: depth + 1)
    }

    func _enter(_ node: Node, environment: inout UVEnvironmentValues) throws {
        let commandBuffer = try environment.commandBuffer.orThrow(.missingEnvironment(\.commandBuffer))
        commandBuffer.pushDebugGroup("RENDER PASS")
        let renderPassDescriptor = try environment.renderPassDescriptor.orThrow(.missingEnvironment(\.renderPassDescriptor))
        let renderCommandEncoder = try commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor).orThrow(.resourceCreationFailure)
        environment.renderCommandEncoder = renderCommandEncoder
    }

    func _exit(_ node: Node, environment: UVEnvironmentValues) throws {
        let commandBuffer = try environment.commandBuffer.orThrow(.missingEnvironment(\.commandBuffer))
        let renderCommandEncoder = try environment.renderCommandEncoder.orThrow(.missingEnvironment(\.renderCommandEncoder))
        renderCommandEncoder.endEncoding()
        commandBuffer.popDebugGroup()
    }
}
