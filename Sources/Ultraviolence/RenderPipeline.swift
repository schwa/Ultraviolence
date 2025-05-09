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

    public init(vertexShader: VertexShader, fragmentShader: FragmentShader, @ElementBuilder content: () throws -> Content) throws {
        self.vertexShader = vertexShader
        self.fragmentShader = fragmentShader
        self.content = try content()
    }

    func setupEnter(_ node: Node) throws {
        let environment = node.environmentValues

        let renderPassDescriptor = try environment.renderPassDescriptor.orThrow(.missingEnvironment(\.renderPassDescriptor)).copyWithType(MTLRenderPassDescriptor.self)

        let renderPipelineDescriptor = try environment.renderPipelineDescriptor.orThrow(.missingEnvironment(\.renderPipelineDescriptor))
        renderPipelineDescriptor.vertexFunction = vertexShader.function
        renderPipelineDescriptor.fragmentFunction = fragmentShader.function

        guard let vertexDescriptor = environment.vertexDescriptor ?? vertexShader.vertexDescriptor else {
            // TODO: #101 We were falling back to vertexShader.vertexDescriptor but that seems to be unreliable.
            throw UltraviolenceError.generic("No vertex descriptor")
        }
        renderPipelineDescriptor.vertexDescriptor = vertexDescriptor

        // TODO: #102 We don't want to overwrite anything already set.
        // TODO: #103 This is copying everything from the render pass descriptor. But really we should be getting this entirely from the enviroment.
        if let colorAttachment0Texture = renderPassDescriptor.colorAttachments[0].texture {
            renderPipelineDescriptor.colorAttachments[0].pixelFormat = colorAttachment0Texture.pixelFormat
        }
        if let depthAttachmentTexture = renderPassDescriptor.depthAttachment?.texture {
            renderPipelineDescriptor.depthAttachmentPixelFormat = depthAttachmentTexture.pixelFormat
        }
        if let stencilAttachmentTexture = renderPassDescriptor.stencilAttachment?.texture {
            renderPipelineDescriptor.stencilAttachmentPixelFormat = stencilAttachmentTexture.pixelFormat
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
