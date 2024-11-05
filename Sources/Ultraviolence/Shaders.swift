internal import UltraviolenceSupport
import Metal

public struct VertexShader: RenderPass {
    public typealias Body = Never

    var function: MTLFunction

    public init(_ name: String) {
        fatalError("Not implemented")
    }

    public init(_ name: String, source: String) throws {
        let device = MTLCreateSystemDefaultDevice()!
        let library = try device.makeLibrary(source: source, options: nil)
        function = library.makeFunction(name: name)!
    }

    public func visit(_ visitor: inout Visitor) throws {
        let renderPipelineDescriptor = try visitor.renderPipelineDescriptor.orThrow(.missingEnvironment(".renderPipelineDescriptor"))

        assert(renderPipelineDescriptor.vertexFunction == nil)
        guard let vertexAttributes = function.vertexAttributes else {
            fatalError("Cannot get vertex attributes from vertex function")
        }
        let vertexDescriptor = MTLVertexDescriptor(vertexAttributes: vertexAttributes)
        renderPipelineDescriptor.vertexDescriptor = vertexDescriptor
        renderPipelineDescriptor.vertexFunction = function
    }
}

public struct FragmentShader: RenderPass {
    public typealias Body = Never

    var function: MTLFunction

    public init(_ name: String) {
        fatalError("Not implemented")
    }

    public init(_ name: String, source: String) throws {
        let device = MTLCreateSystemDefaultDevice()!
        let library = try device.makeLibrary(source: source, options: nil)
        function = library.makeFunction(name: name)!
    }

    public func visit(_ visitor: inout Visitor) throws {
        let renderPipelineDescriptor = try visitor.renderPipelineDescriptor.orThrow(.missingEnvironment(".renderPipelineDescriptor"))
        assert(renderPipelineDescriptor.fragmentFunction == nil)
        renderPipelineDescriptor.fragmentFunction = function
    }
}

public struct ComputeShader: RenderPass {
    public typealias Body = Never

    var function: MTLFunction

    public init(_ name: String) {
        fatalError("Not implemented")
    }

    public init(_ name: String, source: String) throws {
        let device = MTLCreateSystemDefaultDevice()!
        let library = try device.makeLibrary(source: source, options: nil)
        function = library.makeFunction(name: name)!
    }

    public func visit(_ visitor: inout Visitor) throws {
        print("Insert")
        visitor.insert(.function(function))
    }
}
