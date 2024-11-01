import Metal

public struct VertexShader: RenderPass {
    public typealias Body = Never

    var function: MTLFunction

    public init(_ name: String) {
        fatalError()
    }

    public init(_ name: String, source: String) throws {
        let device = MTLCreateSystemDefaultDevice()!
        let library = try device.makeLibrary(source: source, options: nil)
        function = library.makeFunction(name: name)!
    }

    public func render(_ state: inout RenderState) throws {
        assert(state.pipelineDescriptor.vertexFunction == nil)
        guard let vertexAttributes = function.vertexAttributes else {
            fatalError("Cannot get vertex attributes from vertex function")
        }
        let vertexDescriptor = MTLVertexDescriptor(vertexAttributes: vertexAttributes)
        state.pipelineDescriptor.vertexDescriptor = vertexDescriptor
        state.pipelineDescriptor.vertexFunction = function
    }
}


public struct FragmentShader: RenderPass {
    public typealias Body = Never

    var function: MTLFunction

    public init(_ name: String) {
        fatalError()
    }

    public init(_ name: String, source: String) throws {
        let device = MTLCreateSystemDefaultDevice()!
        let library = try device.makeLibrary(source: source, options: nil)
        function = library.makeFunction(name: name)!
    }

    public func render(_ state: inout RenderState) throws {
        assert(state.pipelineDescriptor.fragmentFunction == nil)
        state.pipelineDescriptor.fragmentFunction = function
    }
}

