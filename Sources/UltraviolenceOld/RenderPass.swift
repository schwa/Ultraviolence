import Metal
import simd

// TODO: Rename. We have a `Compute: RenderPass` and that just doesn't make sense.
public protocol RenderPass {
    associatedtype Body: RenderPass

    @RenderPassBuilder
    var body: Body { get throws }

    func visit(visitor: inout Visitor) throws
}

public extension RenderPass {
    func visit(visitor: inout Visitor) throws {
        try visitor.log(node: self) { visitor in
            try body.visit(visitor: &visitor)
        }
    }
}

// MARK: -

public extension RenderPass where Body == Never {
    var body: Never {
        get throws {
            fatalError("No body for \(type(of: self))")
        }
    }
}

extension Never: RenderPass {
    public typealias Body = Never
}

// MARK: -

extension Optional: RenderPass where Wrapped: RenderPass {
    public typealias Body = Never

    public func visit(visitor: inout Visitor) throws {
        try visitor.log(node: self) { visitor in
            try self?.visit(visitor: &visitor)
        }
    }
}
