import Metal
import UltraviolenceSupport

public struct RenderPipeline <Content>: BodylessElement where Content: Element {
    public typealias Body = Never
    @UVEnvironment(\.device)
    var device

    @UVEnvironment(\.depthStencilState)
    var depthStencilState

    var vertexShader: VertexShader
    var fragmentShader: FragmentShader
    var content: Content

    @UVState
    var renderPipelineState: MTLRenderPipelineState?

    @UVState
    var reflection: Reflection?

    public init(vertexShader: VertexShader, fragmentShader: FragmentShader, @ElementBuilder content: () -> Content) {
        self.vertexShader = vertexShader
        self.fragmentShader = fragmentShader
        self.content = content()
    }

    func _expandNode(_ node: Node, depth: Int) throws {
        // TODO: Replace with `BodylessContentElement`?
        guard let graph = node.graph else {
            preconditionFailure("Cannot build node tree without a graph.")
        }
        if node.children.isEmpty {
            node.children.append(graph.makeNode())
        }
        try content.expandNode(node.children[0], depth: depth + 1)

        let environment = node.environmentValues

        let renderPassDescriptor = try environment.renderPassDescriptor.orThrow(.missingEnvironment(\.renderPassDescriptor))
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = vertexShader.function
        renderPipelineDescriptor.fragmentFunction = fragmentShader.function
        guard let vertexDescriptor = environment.vertexDescriptor ?? vertexShader.vertexDescriptor else {
            throw UltraviolenceError.undefined
        }
        renderPipelineDescriptor.vertexDescriptor = vertexDescriptor
        let colorAttachment0Texture = try renderPassDescriptor.colorAttachments[0].texture.orThrow(.undefined)
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = colorAttachment0Texture.pixelFormat
        let depthAttachmentTexture = try renderPassDescriptor.depthAttachment.orThrow(.undefined).texture.orThrow(.undefined)
        renderPipelineDescriptor.depthAttachmentPixelFormat = depthAttachmentTexture.pixelFormat
        let device = try device.orThrow(.missingEnvironment(\.device))
        let (renderPipelineState, reflection) = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor, options: .bindingInfo)
        self.renderPipelineState = renderPipelineState
        self.reflection = .init(reflection.orFatalError(.resourceCreationFailure))

        if environment.depthStencilState == nil, let depthStencilDescriptor = environment.depthStencilDescriptor {
            let depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)
            node.environmentValues.depthStencilState = depthStencilState
        }

        node.environmentValues.renderPipelineState = renderPipelineState
        node.environmentValues.reflection = self.reflection
    }

    func workloadEnter(_ node: Node) throws {
        let renderCommandEncoder = try node.environmentValues.renderCommandEncoder.orThrow(.missingEnvironment(\.renderCommandEncoder))
        let renderPipelineState = try node.environmentValues.renderPipelineState.orThrow(.missingEnvironment(\.renderPipelineState))

        if let depthStencilState {
            renderCommandEncoder.setDepthStencilState(depthStencilState)
        }

        renderCommandEncoder.setRenderPipelineState(renderPipelineState)
    }
}
