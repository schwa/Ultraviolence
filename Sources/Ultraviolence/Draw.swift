import Metal

public struct Draw: RenderPass, BodylessRenderPass {
    public typealias Body = Never

    var encodeGeometry: (MTLRenderCommandEncoder) throws -> Void

    public init(encodeGeometry: @escaping (MTLRenderCommandEncoder) throws -> Void) {
        self.encodeGeometry = encodeGeometry
    }

    func _expandNode(_ node: Node) throws {
        // This line intentionally left blank.
    }

    func _enter(_ node: Node, environment: inout EnvironmentValues) throws {
        let renderCommandEncoder = try environment.renderCommandEncoder.orThrow(.missingEnvironment(\.renderCommandEncoder))
        try encodeGeometry(renderCommandEncoder)
    }
}
