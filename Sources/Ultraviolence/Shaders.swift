internal import BaseSupport
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

    public func visit(_ visitor: inout Visitor) throws {
        assert(visitor.renderPipelineDescriptor.vertexFunction == nil)
        guard let vertexAttributes = function.vertexAttributes else {
            fatalError("Cannot get vertex attributes from vertex function")
        }
        let vertexDescriptor = MTLVertexDescriptor(vertexAttributes: vertexAttributes)
        visitor.renderPipelineDescriptor.vertexDescriptor = vertexDescriptor
        visitor.renderPipelineDescriptor.vertexFunction = function
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

    public func visit(_ visitor: inout Visitor) throws {
        assert(visitor.renderPipelineDescriptor.fragmentFunction == nil)
        visitor.renderPipelineDescriptor.fragmentFunction = function
    }
}

public struct ComputeShader: RenderPass {
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

    public func visit(_ visitor: inout Visitor) throws {
        visitor.insert(.function(function))
    }
}

