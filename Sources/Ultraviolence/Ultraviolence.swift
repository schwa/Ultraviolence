import Metal
import simd

public protocol RenderPass {
    associatedtype Body: RenderPass

    @RenderPassBuilder
    var body: Body { get }

    func render(_ state: inout RenderState) throws
}

extension RenderPass {
    public func render(_ state: inout RenderState) throws {
        try body.render(&state)
    }
}

extension Never: RenderPass {
}

public struct EmptyPass: RenderPass {
    public typealias Body = Never
}

extension Optional: RenderPass where Wrapped: RenderPass {
    public typealias Body = Never
}

extension RenderPass where Body == Never {
    public var body: Never {
        fatalError()
    }
}

@resultBuilder
public struct RenderPassBuilder {
    public static func buildBlock() -> some RenderPass {
        EmptyPass()
    }

    public static func buildBlock<Content>(_ content: Content) -> Content where Content: RenderPass {
        content
    }

    public static func buildBlock<each Content>(_ content: repeat each Content) -> TuplePass<repeat each Content> where repeat each Content: RenderPass {
        TuplePass(repeat each content)
    }

    public static func buildOptional<Content>(_ content: Content?) -> some RenderPass where Content: RenderPass {
        content
    }
}

public struct TuplePass <each T: RenderPass>: RenderPass {
    public typealias Body = Never
    var value: (repeat each T)

    public init(_ value: repeat each T) {
        self.value = (repeat each value)
    }

    public func render(_ state: inout RenderState) throws {
        for element in repeat (each value) {
            try element.render(&state)
        }
    }
}

// MARK; -

public struct Draw <Content: RenderPass>: RenderPass where Content: RenderPass {
    public typealias Body = Never

    var geometry: [Geometry]
    var content: Content

    public init(_ geometry: [Geometry], @RenderPassBuilder content: () throws -> Content) throws {
        self.geometry = geometry
        self.content = try content()
    }

    public func render(_ state: inout RenderState) throws {

        let device = state.encoder.device

        try content.render(&state)

        let renderPipelineState = try device.makeRenderPipelineState(descriptor: state.pipelineDescriptor)
        state.encoder.setRenderPipelineState(renderPipelineState)

        for element in geometry {
            let triangles = element.vertices(for: .triangle)
            triangles.withUnsafeBytes { buffer in
                state.encoder.setVertexBytes(buffer.baseAddress!, length: buffer.count, index: 0)
            }
            state.encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: triangles.count)
        }
    }
}

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
        state.pipelineDescriptor.fragmentFunction = function
    }
}

