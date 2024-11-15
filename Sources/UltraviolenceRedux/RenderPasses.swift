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
}

// MARK: -

public struct VertexShader {
    let function: MTLFunction

    public init(source: String) throws {
        let device = MTLCreateSystemDefaultDevice()!
        let library = try device.makeLibrary(source: source, options: nil)
        function = library.functionNames.compactMap { library.makeFunction(name: $0)  }.first(where: { $0.functionType == .vertex })!
    }
}

public struct FragmentShader {
    let function: MTLFunction

    public init(source: String) throws {
        let device = MTLCreateSystemDefaultDevice()!
        let library = try device.makeLibrary(source: source, options: nil)
        function = library.functionNames.compactMap { library.makeFunction(name: $0)  }.first(where: { $0.functionType == .fragment })!
    }
}

// MARK: -

public extension RenderPass {
    func argument(type: MTLFunctionType, name: String, value: Any) -> some RenderPass {
        // TODO: Implement this.
        return self
    }
}

// MARK: -

public struct Render <Content>: RenderPass where Content: RenderPass {
    var content: Content

    public init(content: () -> Content) {
        self.content = content()
    }

    public var body: some RenderPass {
        content
    }
}

public struct RenderPipeline <Content>: RenderPass where Content: RenderPass {
    @Environment(\.device)
    var device

    @Environment(\.renderPassDescriptor)
    var renderPassDescriptor

    @Environment(\.vertexDescriptor)
    var vertexDescriptor

    var vertexShader: VertexShader
    var fragmentShader: FragmentShader
    var content: Content

    public init(vertexShader: VertexShader, fragmentShader: FragmentShader, content: () -> Content) {
        self.vertexShader = vertexShader
        self.fragmentShader = fragmentShader
        self.content = content()
    }

    public var body: some RenderPass {
        // TODO: Move this to a onSetup()
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = vertexShader.function
        renderPipelineDescriptor.fragmentFunction = fragmentShader.function
        renderPipelineDescriptor.vertexDescriptor = vertexDescriptor!
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = renderPassDescriptor!.colorAttachments[0].texture!.pixelFormat
        renderPipelineDescriptor.depthAttachmentPixelFormat = renderPassDescriptor!.depthAttachment!.texture!.pixelFormat
        let renderPipelineState = try! device!.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        return content.environment(\.renderPipelineState, renderPipelineState)
    }
}

public struct Draw: RenderPass, BodylessRenderPass {
    public typealias Body = Never

    var encodeGeometry: (MTLRenderCommandEncoder) throws -> Void

    public init(encodeGeometry: @escaping (MTLRenderCommandEncoder) throws -> Void) {
        self.encodeGeometry = encodeGeometry
    }

    func _expandNode(_ node: Node) {
    }

    func _setup(_ node: Node) {
        print("DRAW SETUP")
    }

}

