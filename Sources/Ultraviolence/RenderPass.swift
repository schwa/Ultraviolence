import Metal
import simd

public protocol RenderPass {
    associatedtype Body: RenderPass

    @RenderPassBuilder
    var body: Body { get }

    func visit(_ visitor: inout Visitor) throws
}

extension RenderPass {
    public func visit(_ visitor: inout Visitor) throws {
        try body.visit(&visitor)
    }
}

// MARK: -

extension RenderPass where Body == Never {
    public var body: Never {
        fatalError("No body for \(type(of: self))")
    }
}

extension Never: RenderPass {
}

// MARK: -

extension Optional: RenderPass where Wrapped: RenderPass {
    public typealias Body = Never
}
