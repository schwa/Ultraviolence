import Metal

public struct Render <Content>: RenderPass where Content: RenderPass {
    var content: Content

    public init(content: () -> Content) {
        self.content = content()
    }

    public var body: some RenderPass {
        content
    }
}

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

public struct RenderPipeline <Content>: RenderPass, BuiltinRenderPass where Content: RenderPass {

    public typealias Body = Never

    var content: Content

    public init(vertexShader: VertexShader, fragmentShader: FragmentShader, content: () -> Content) {
        self.content = content()
    }

    func _buildNodeTree(_ parent: Node) {


        let node = Node(graph: parent.graph)

        AnyBuiltinRenderPass(content)._buildNodeTree(node)




//        fatalError()
    }

    func _setup(_ node: Node) {
        print("SETUP")
    }

}

public struct Draw: RenderPass, BuiltinRenderPass {
    var encodeGeometry: (MTLRenderCommandEncoder) throws -> Void

    public init(encodeGeometry: @escaping (MTLRenderCommandEncoder) throws -> Void) {
        self.encodeGeometry = encodeGeometry
    }

    func _buildNodeTree(_ parent: Node) {

    }
}

public extension RenderPass {
    func argument(type: MTLFunctionType, name: String, value: Any) -> some RenderPass {
        return self
    }
}
