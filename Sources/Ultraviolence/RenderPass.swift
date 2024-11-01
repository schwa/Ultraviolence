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
