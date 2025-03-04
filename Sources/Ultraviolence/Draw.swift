import Metal

// TODO: this is no different than a EncivonmentReader<RenderCOmmandEncoder>
public struct Draw: Element, BodylessElement {
    public typealias Body = Never

    var encodeGeometry: (MTLRenderCommandEncoder) throws -> Void

    public init(encodeGeometry: @escaping (MTLRenderCommandEncoder) throws -> Void) {
        self.encodeGeometry = encodeGeometry
    }

    func _expandNode(_ node: Node, context: ExpansionContext) throws {
        // This line intentionally left blank.
    }

    func workloadEnter(_ node: Node) throws {
        let renderCommandEncoder = try node.environmentValues.renderCommandEncoder.orThrow(.missingEnvironment(\.renderCommandEncoder))
        try encodeGeometry(renderCommandEncoder)
    }
}
