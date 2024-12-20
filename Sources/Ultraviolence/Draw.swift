import Metal

public struct Draw: RenderPass, BodylessRenderPass {
    public typealias Body = Never

    @Environment(\.renderCommandEncoder)
    var renderCommandEncoder

    var encodeGeometry: (MTLRenderCommandEncoder) throws -> Void

    public init(encodeGeometry: @escaping (MTLRenderCommandEncoder) throws -> Void) {
        self.encodeGeometry = encodeGeometry
    }

    func _expandNode(_ node: Node) throws {
        // This line intentionally left blank.
    }

    func _enter(_ node: Node) throws {
        try encodeGeometry(renderCommandEncoder.orThrow(.missingEnvironment("renderCommandEncoder")))
    }
}
