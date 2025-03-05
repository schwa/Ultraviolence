import Metal
internal import os
import UltraviolenceSupport

internal extension Element {
    var shortDescription: String {
        "\(type(of: self))"
    }
}

public extension UltraviolenceError {
    static func missingEnvironment(_ key: PartialKeyPath<UVEnvironmentValues>) -> Self {
        missingEnvironment("\(key)")
    }
}

internal struct IdentifiableBox <Key, Value>: Identifiable where Key: Hashable {
    var id: Key
    var value: Value
}

internal extension IdentifiableBox where Key == ObjectIdentifier, Value: AnyObject {
    init(_ value: Value) {
        self.id = ObjectIdentifier(value)
        self.value = value
    }
}

internal extension Element {
    func _dump(to output: inout some TextOutputStream) throws {
        let graph = try Graph(content: self)
        try graph.rebuildIfNeeded()
        try graph.dump(to: &output)
    }

    func _dump() throws {
        var output = String()
        try _dump(to: &output)
        print(output)
    }
}

@MainActor
internal extension Node {
    var shortDescription: String {
        self.element?.shortDescription ?? "<empty>"
    }
}

public extension Element {
    // TODO: Not keen on this being optional.
    // TODO: Need a compute variant of this.
    func useResource(_ resource: (any MTLResource)?, usage: MTLResourceUsage, stages: MTLRenderStages) -> some Element {
        onWorkloadEnter { environmentValues in
            if let resource {
                let renderCommandEncoder = environmentValues.renderCommandEncoder.orFatalError()
                renderCommandEncoder.useResource(resource, usage: usage, stages: stages)
            }
        }
    }
}
