import Metal
import UltraviolenceSupport

public struct RenderPipeline <Content>: Element, BodylessElement, BodylessContentElement where Content: Element {
    public typealias Body = Never
    @UVEnvironment(\.device)
    var device

    @UVEnvironment(\.depthStencilState)
    var depthStencilState

    var label: String?
    var vertexShader: VertexShader
    var fragmentShader: FragmentShader
    var content: Content

    @UVState
    var reflection: Reflection?

    public init(label: String? = nil, vertexShader: VertexShader, fragmentShader: FragmentShader, @ElementBuilder content: () throws -> Content) throws {
        self.label = label
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

        if let linkedFunctions = node.environmentValues.linkedFunctions {
            // TODO: How do we handle separate linked functions for vertex and fragment? [FILE ME]
            renderPipelineDescriptor.vertexLinkedFunctions = linkedFunctions
            renderPipelineDescriptor.fragmentLinkedFunctions = linkedFunctions
        }

        if let vertexDescriptor = environment.vertexDescriptor {
            renderPipelineDescriptor.vertexDescriptor = vertexDescriptor
        }

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
        if let label {
            renderPipelineDescriptor.label = label
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
        logger?.verbose?.info("Start render pipeline: \(label ?? "<unlabeled>") (\(node.element.debugName))")

        let renderCommandEncoder = try node.environmentValues.renderCommandEncoder.orThrow(.missingEnvironment(\.renderCommandEncoder))
        let renderPipelineState = try node.environmentValues.renderPipelineState.orThrow(.missingEnvironment(\.renderPipelineState))

        if let depthStencilState {
            renderCommandEncoder.setDepthStencilState(depthStencilState)
        }

        renderCommandEncoder.setRenderPipelineState(renderPipelineState)
    }

    func workloadExit(_ node: Node) throws {
        logger?.verbose?.info("Exit render pipeline: \(label ?? "<unlabeled>") (\(node.element.debugName))")
    }

    nonisolated func requiresSetup(comparedTo old: RenderPipeline<Content>) -> Bool {
        // For now, always return false since shaders rarely change after initial setup
        // This prevents pipeline recreation on every frame
        // TODO: Implement proper comparison when shader constants are added
        false
    }
}
