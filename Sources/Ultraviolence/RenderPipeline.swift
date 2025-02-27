import Metal
import UltraviolenceSupport

public struct RenderPipeline <Content>: Element, BodylessElement, BodylessContentElement where Content: Element {
    public typealias Body = Never
    @UVEnvironment(\.device)
    var device

    @UVEnvironment(\.depthStencilState)
    var depthStencilState

    var vertexShader: VertexShader
    var fragmentShader: FragmentShader
    var content: Content

    @UVState
    var reflection: Reflection?

    public init(vertexShader: VertexShader, fragmentShader: FragmentShader, @ElementBuilder content: () -> Content) {
        self.vertexShader = vertexShader
        self.fragmentShader = fragmentShader
        self.content = content()
    }

    func setupEnter(_ node: Node) throws {
        let environment = node.environmentValues

        let renderPassDescriptor = try environment.renderPassDescriptor.orThrow(.missingEnvironment(\.renderPassDescriptor))
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = vertexShader.function
        renderPipelineDescriptor.fragmentFunction = fragmentShader.function
        guard let vertexDescriptor = environment.vertexDescriptor ?? vertexShader.vertexDescriptor else {
            // TODO: We were falling back to vertexShader.vertexDescriptor but that seems to be unreliable.
            throw UltraviolenceError.generic("No vertex descriptor")
        }
        renderPipelineDescriptor.vertexDescriptor = vertexDescriptor

        // TODO: This is copying everything from the render pass descriptor. But really we should be getting this entirely from the enviroment.
        let colorAttachment0Texture = try renderPassDescriptor.colorAttachments[0].texture.orThrow(.generic("No color attachment 0 texture"))
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = colorAttachment0Texture.pixelFormat
        if let depthAttachmentTexture = renderPassDescriptor.depthAttachment?.texture {
            renderPipelineDescriptor.depthAttachmentPixelFormat = depthAttachmentTexture.pixelFormat
        }

        let device = try device.orThrow(.missingEnvironment(\.device))
        let (renderPipelineState, reflection) = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor, options: .bindingInfo)
        self.reflection = .init(reflection.orFatalError(.resourceCreationFailure("Failed to create reflection.")))

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
