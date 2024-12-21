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

extension RenderPass {
    func _process(log: Bool = true) throws {
        let logger = log ? logger : nil

        var enviromentStack: [EnvironmentValues] = [.init()]
        let graph = try Graph(content: self)
        try graph.visit { _, _ in
            // This line intentionally left blank.
        }
        enter: { node in
            var environment = node.environmentValues
            environment.merge(enviromentStack.last!)

            logger?.log("Entering: \(node.shortDescription)")
            if let body = node.renderPass as? any BodylessRenderPass {
                try body._enter(node, environment: &environment)
            }
            enviromentStack.append(environment)
        }
        exit: { node in
            var environment = node.environmentValues
            environment.merge(enviromentStack.last!)
            enviromentStack.removeLast()

            if let body = node.renderPass as? any BodylessRenderPass {
                try body._exit(node, environment: environment)
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
