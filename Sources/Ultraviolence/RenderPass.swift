import Metal
import simd

// TODO: Rename. We have a `Compute: RenderPass` and that just doesn't make sense.
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
        get throws {            
            fatalError("No body for \(type(of: self))")
        }
    }
}

extension Never: RenderPass {
}

// MARK: -

extension Optional: RenderPass where Wrapped: RenderPass {
    public typealias Body = Never

    public func visit(_ visitor: inout Visitor) throws {
        // swiftlint:disable:next self_binding
        if let value = self {
            try value.visit(&visitor)
        }
    }
}
