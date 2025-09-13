import Metal

// Note: Cannot use EnvironmentReader here because Draw needs to execute during the workload phase when the render command encoder is available, not during the tree expansion phase where EnvironmentReader operates.
public struct Draw: Element, BodylessElement {
    public typealias Body = Never

    var encodeGeometry: (MTLRenderCommandEncoder) throws -> Void

    public init(encodeGeometry: @escaping (MTLRenderCommandEncoder) throws -> Void) {
        self.encodeGeometry = encodeGeometry
    }

    func workloadEnter(_ node: Node) throws {
        let renderCommandEncoder = try node.environmentValues.renderCommandEncoder.orThrow(.missingEnvironment(\.renderCommandEncoder))
        try encodeGeometry(renderCommandEncoder)
    }
}
