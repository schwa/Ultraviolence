import Metal
import UltraviolenceSupport

public struct MeshRenderPipeline <Content>: Element, BodylessElement, BodylessContentElement where Content: Element {
    public typealias Body = Never
    @UVEnvironment(\.device)
    var device

    @UVEnvironment(\.depthStencilState)
    var depthStencilState

    var label: String?
    var objectShader: ObjectShader?
    var meshShader: MeshShader
    var fragmentShader: FragmentShader
    var content: Content

    @UVState
    var reflection: Reflection?

    public init(label: String? = nil, objectShader: ObjectShader? = nil, meshShader: MeshShader, fragmentShader: FragmentShader, @ElementBuilder content: () throws -> Content) throws {
        self.label = label
        self.objectShader = objectShader
        self.meshShader = meshShader
        self.fragmentShader = fragmentShader
        self.content = try content()
    }

    func setupEnter(_ node: Node) throws {
        let environment = node.environmentValues

        let renderPassDescriptor = try environment.renderPassDescriptor.orThrow(.missingEnvironment(\.renderPassDescriptor)).copyWithType(MTLRenderPassDescriptor.self)

        let meshRenderPipelineDescriptor = MTLMeshRenderPipelineDescriptor()
        meshRenderPipelineDescriptor.objectFunction = objectShader?.function
        meshRenderPipelineDescriptor.meshFunction = meshShader.function
        meshRenderPipelineDescriptor.fragmentFunction = fragmentShader.function

        if let linkedFunctions = node.environmentValues.linkedFunctions {
            meshRenderPipelineDescriptor.objectLinkedFunctions = linkedFunctions
            meshRenderPipelineDescriptor.meshLinkedFunctions = linkedFunctions
            meshRenderPipelineDescriptor.fragmentLinkedFunctions = linkedFunctions
        }

        if let colorAttachment0Texture = renderPassDescriptor.colorAttachments[0].texture {
            meshRenderPipelineDescriptor.colorAttachments[0].pixelFormat = colorAttachment0Texture.pixelFormat
        }
        if let depthAttachmentTexture = renderPassDescriptor.depthAttachment?.texture {
            meshRenderPipelineDescriptor.depthAttachmentPixelFormat = depthAttachmentTexture.pixelFormat
        }
        if let stencilAttachmentTexture = renderPassDescriptor.stencilAttachment?.texture {
            meshRenderPipelineDescriptor.stencilAttachmentPixelFormat = stencilAttachmentTexture.pixelFormat
        }
        if let label {
            meshRenderPipelineDescriptor.label = label
        }
        let device = try device.orThrow(.missingEnvironment(\.device))
        let (renderPipelineState, reflection) = try device.makeRenderPipelineState(descriptor: meshRenderPipelineDescriptor, options: .bindingInfo)
        self.reflection = .init(reflection.orFatalError(.resourceCreationFailure("Failed to create reflection.")))

        if environment.depthStencilState == nil, let depthStencilDescriptor = environment.depthStencilDescriptor {
            let depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)
            node.environmentValues.depthStencilState = depthStencilState
        }

        node.environmentValues.renderPipelineState = renderPipelineState
        node.environmentValues.reflection = self.reflection
    }

    func workloadEnter(_ node: Node) throws {
        logger?.verbose?.info("Start mesh render pipeline: \(label ?? "<unlabeled>") (\(node.element.debugName))")

        let renderCommandEncoder = try node.environmentValues.renderCommandEncoder.orThrow(.missingEnvironment(\.renderCommandEncoder))
        let renderPipelineState = try node.environmentValues.renderPipelineState.orThrow(.missingEnvironment(\.renderPipelineState))

        if let depthStencilState {
            renderCommandEncoder.setDepthStencilState(depthStencilState)
        }

        renderCommandEncoder.setRenderPipelineState(renderPipelineState)
    }

    func workloadExit(_ node: Node) throws {
        logger?.verbose?.info("Exit mesh render pipeline: \(label ?? "<unlabeled>") (\(node.element.debugName))")
    }

    nonisolated func requiresSetup(comparedTo old: MeshRenderPipeline<Content>) -> Bool {
        false
    }
}
