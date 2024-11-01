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

// MARK: -

public struct EmptyPass: RenderPass {
    public typealias Body = Never
}

extension RenderPass where Body == Never {
    public var body: Never {
        fatalError()
    }
}

extension Never: RenderPass {
}

// MARK: -

extension Optional: RenderPass where Wrapped: RenderPass {
    public typealias Body = Never
}

// MARK: -

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

// MARK: -

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
