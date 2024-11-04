import Metal
import simd

public protocol RenderPass {
    associatedtype Body: RenderPass

    @RenderPassBuilder
    var body: Body { get throws }

    func visit(_ visitor: inout Visitor) throws
}

public extension RenderPass {
    func visit(_ visitor: inout Visitor) throws {
        try body.visit(&visitor)
    }
}

// MARK: -

public extension RenderPass where Body == Never {
    var body: Never {
        fatalError("No body for \(type(of: self))")
    }
}

extension Never: RenderPass {
}

// MARK: -

extension Optional: RenderPass where Wrapped: RenderPass {
    public typealias Body = Never
}
