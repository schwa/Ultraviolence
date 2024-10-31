import Metal
import simd

public protocol RenderPass {
    associatedtype Body: RenderPass

    @RenderPassBuilder
    var body: Body { get }

    func encode(encoder: MTLRenderCommandEncoder) throws
}

extension RenderPass {
    public func encode(encoder: MTLRenderCommandEncoder) throws {
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

    public func encode(encoder: MTLRenderCommandEncoder) throws {
        for element in repeat (each value) {
            try element.encode(encoder: encoder)
        }
    }
}

// MARK; -

public struct Draw <Content: RenderPass>: RenderPass where Content: RenderPass {
    public typealias Body = Never

    var geometry: [Geometry]
    var content: Content

    public init(_ geometry: [Geometry], @RenderPassBuilder content: () -> Content) {
        self.geometry = geometry
        self.content = content()
    }

    public func encode(encoder: MTLRenderCommandEncoder) throws {
        try content.encode(encoder: encoder)
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

    public func encode(encoder: MTLRenderCommandEncoder) throws {
        let device = encoder.device
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = function
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm_srgb
        let renderPipelineState = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor)
        encoder.setRenderPipelineState(renderPipelineState)

        print("Encode vertex shader")
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
}

