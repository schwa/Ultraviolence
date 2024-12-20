import Metal
import UltraviolenceSupport

public extension EnvironmentValues {
    @Entry var device: MTLDevice?
    @Entry var commandQueue: MTLCommandQueue?
    @Entry var commandBuffer: MTLCommandBuffer?
    @Entry var renderCommandEncoder: MTLRenderCommandEncoder?
    @Entry var renderPassDescriptor: MTLRenderPassDescriptor?
    @Entry var renderPipelineState: MTLRenderPipelineState?
    @Entry var vertexDescriptor: MTLVertexDescriptor?
    @available(*, deprecated, message: "Deprecated. Use ``.reflection``.")
    @Entry var renderPipelineReflection: MTLRenderPipelineReflection?
    @Entry var depthStencilDescriptor: MTLDepthStencilDescriptor?
    @Entry var depthStencilState: MTLDepthStencilState?
    @Entry var computeCommandEncoder: MTLComputeCommandEncoder?
    @Entry var computePipelineState: MTLComputePipelineState?
    @Entry var reflection: Reflection?
    @Entry var colorAttachment: (MTLTexture, Int)?
    @Entry var depthAttachment: MTLTexture?
}

public extension RenderPass {
    func colorAttachment(_ texture: MTLTexture, index: Int) -> some RenderPass {
        environment(\.colorAttachment, (texture, index))
    }
    func depthAttachment(_ texture: MTLTexture) -> some RenderPass {
        environment(\.depthAttachment, texture)
    }
}

public extension RenderPass {
    func vertexDescriptor(_ vertexDescriptor: MTLVertexDescriptor) -> some RenderPass {
        environment(\.vertexDescriptor, vertexDescriptor)
    }

    func depthStencilDescriptor(_ depthStencilDescriptor: MTLDepthStencilDescriptor) -> some RenderPass {
        environment(\.depthStencilDescriptor, depthStencilDescriptor)
    }

    func depthCompare(function: MTLCompareFunction, enabled: Bool) -> some RenderPass {
        depthStencilDescriptor(.init(depthCompareFunction: function, isDepthWriteEnabled: enabled))
    }
}

// MARK: -

public struct VertexShader {
    let function: MTLFunction

    public init(source: String) throws {
        let device = try MTLCreateSystemDefaultDevice().orThrow(.resourceCreationFailure)
        let library = try device.makeLibrary(source: source, options: nil)
        function = try library.functionNames.compactMap { library.makeFunction(name: $0) }.first { $0.functionType == .vertex }.orThrow(.resourceCreationFailure)
    }
}

public struct FragmentShader {
    let function: MTLFunction

    public init(source: String) throws {
        let device = try MTLCreateSystemDefaultDevice().orThrow(.resourceCreationFailure)
        let library = try device.makeLibrary(source: source, options: nil)
        function = try library.functionNames.compactMap { library.makeFunction(name: $0) }.first { $0.functionType == .fragment }.orThrow(.resourceCreationFailure)
    }
}

public extension VertexShader {
    var vertexDescriptor: MTLVertexDescriptor? {
        function.vertexDescriptor
    }
}

// MARK: -

// TODO: this should really be called renderpass
public struct Render <Content>: RenderPass, BodylessRenderPass where Content: RenderPass {
    var content: Content

    @Environment(\.commandBuffer)
    var commandBuffer

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
}

extension RenderPass {
    // TODO: Rename.
    // TODO: Share with OffscreenRenderer and RenderView.
    func _process(log: Bool = true) throws {
        let logger = log ? logger : nil

        let graph = try Graph(content: self)
        try graph.visit { _, _ in
            // This line intentionally left blank.
        }
        enter: { node in
            logger?.log("Entering: \(node.shortDescription)")
            if let body = node.renderPass as? any BodylessRenderPass {
                try body._enter(node)
            }
        }
        exit: { node in
            if let body = node.renderPass as? any BodylessRenderPass {
                try body._exit(node)
            }
            logger?.log("Exited: \(node.shortDescription)")
        }
    }
}

extension RenderPass {
    func _dump() {
        let graph = try! Graph(content: self)
        graph.dump()
    }
}

@MainActor
extension Node {
    var shortDescription: String {
        "\(self.renderPass!.shortDescription)"
    }
}
