import Metal
import UltraviolenceSupport

public struct RenderPipeline <Content>: BodylessRenderPass where Content: RenderPass {
    public typealias Body = Never
    @Environment(\.device)
    var device

    @Environment(\.renderPassDescriptor)
    var renderPassDescriptor

    @Environment(\.vertexDescriptor)
    var vertexDescriptor

    @Environment(\.depthStencilDescriptor)
    var depthStencilDescriptor

    @Environment(\.depthStencilState)
    var depthStencilState

    @Environment(\.renderCommandEncoder)
    var renderCommandEncoder

    var vertexShader: VertexShader
    var fragmentShader: FragmentShader
    var content: Content

    @State
    var renderPipelineState: MTLRenderPipelineState?

    @State
    var reflection: Reflection?

    public init(vertexShader: VertexShader, fragmentShader: FragmentShader, @RenderPassBuilder content: () -> Content) {
        self.vertexShader = vertexShader
        self.fragmentShader = fragmentShader
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

        let renderPassDescriptor = try renderPassDescriptor.orThrow(.missingEnvironment("renderPassDescriptor"))
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = vertexShader.function
        renderPipelineDescriptor.fragmentFunction = fragmentShader.function
        guard let vertexDescriptor = vertexDescriptor ?? vertexShader.vertexDescriptor else {
            throw UltraviolenceError.undefined
        }
        renderPipelineDescriptor.vertexDescriptor = vertexDescriptor
        let colorAttachment0Texture = try renderPassDescriptor.colorAttachments[0].texture.orThrow(.undefined)
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = colorAttachment0Texture.pixelFormat
        let depthAttachmentTexture = try renderPassDescriptor.depthAttachment.orThrow(.undefined).texture.orThrow(.undefined)
        renderPipelineDescriptor.depthAttachmentPixelFormat = depthAttachmentTexture.pixelFormat
        let device = try device.orThrow(.missingEnvironment("device"))
        let (renderPipelineState, reflection) = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor, options: .bindingInfo)
        self.renderPipelineState = renderPipelineState
        self.reflection = .init(reflection.orFatalError(.resourceCreationFailure))

        if node.environmentValues[keyPath: \.depthStencilState] == nil, let depthStencilDescriptor {
            let depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)
            node.environmentValues[keyPath: \.depthStencilState] = depthStencilState
        }

        node.environmentValues[keyPath: \.renderPipelineState] = renderPipelineState
        node.environmentValues[keyPath: \.reflection] = self.reflection
    }

    func _enter(_ node: Node) throws {
        let renderCommandEncoder = try renderCommandEncoder.orThrow(.missingEnvironment("renderCommandEncoder"))
        let renderPipelineState = try renderPipelineState.orThrow(.missingEnvironment("renderPipelineState"))

        if let depthStencilState {
            renderCommandEncoder.setDepthStencilState(depthStencilState)
        }

        renderCommandEncoder.setRenderPipelineState(renderPipelineState)
    }
}
