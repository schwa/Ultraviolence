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
