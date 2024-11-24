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
        function = library.functionNames.compactMap { library.makeFunction(name: $0) }.first { $0.functionType == .vertex }!
    }
}

public struct FragmentShader {
    let function: MTLFunction

    public init(source: String) throws {
        let device = MTLCreateSystemDefaultDevice()!
        let library = try device.makeLibrary(source: source, options: nil)
        function = library.functionNames.compactMap { library.makeFunction(name: $0) }.first { $0.functionType == .fragment }!
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

    func _expandNode(_ node: Node) {
        // TODO: Move into BodylessRenderPass
        guard let graph = node.graph else {
            fatalError("Cannot build node tree without a graph.")
        }
        if node.children.isEmpty {
            node.children.append(graph.makeNode())
        }
        content.expandNode(node.children[0])
    }

    func drawEnter() {
        print("RENDER: drawEnter")
    }

    func drawExit() {
        print("RENDER: drawExit")
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

    public init(vertexShader: VertexShader, fragmentShader: FragmentShader, @RenderPassBuilder content: () -> Content) {
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

    @Environment(\.commandBuffer)
    var commandBuffer

    var encodeGeometry: (MTLRenderCommandEncoder) throws -> Void

    public init(encodeGeometry: @escaping (MTLRenderCommandEncoder) throws -> Void) {
        self.encodeGeometry = encodeGeometry
    }

    func _expandNode(_ node: Node) {
    }

    func drawEnter() {
        print("drawEnter")
        print(commandBuffer)
    }

    func drawExit() {
        print("drawExit")
    }
}
