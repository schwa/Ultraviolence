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

        guard let vertexDescriptor = environment.vertexDescriptor else {
            try _throw(UltraviolenceError.configurationError("No vertex descriptor provided. Use .vertexDescriptor() modifier or vertexShader.inferredVertexDescriptor() for simple cases."))
        }
        renderPipelineDescriptor.vertexDescriptor = vertexDescriptor

        // Only set pixel formats if they haven't been explicitly configured
        // TODO: #103 This is copying everything from the render pass descriptor. But really we should be getting this entirely from the environment.
        if renderPipelineDescriptor.colorAttachments[0].pixelFormat == .invalid,
           let colorAttachment0Texture = renderPassDescriptor.colorAttachments[0].texture {
            renderPipelineDescriptor.colorAttachments[0].pixelFormat = colorAttachment0Texture.pixelFormat
        }
        if renderPipelineDescriptor.depthAttachmentPixelFormat == .invalid,
           let depthAttachmentTexture = renderPassDescriptor.depthAttachment?.texture {
            renderPipelineDescriptor.depthAttachmentPixelFormat = depthAttachmentTexture.pixelFormat
        }
        if renderPipelineDescriptor.stencilAttachmentPixelFormat == .invalid,
           let stencilAttachmentTexture = renderPassDescriptor.stencilAttachment?.texture {
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

    nonisolated func requiresSetup(comparedTo old: RenderPipeline<Content>) -> Bool {
        // For now, always return false since shaders rarely change after initial setup
        // This prevents pipeline recreation on every frame
        // TODO: Implement proper comparison when shader constants are added
        return false
    }
}
