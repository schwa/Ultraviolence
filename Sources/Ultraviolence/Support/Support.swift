import UltraviolenceSupport

public struct EnvironmentDumper: Element, BodylessElement {
    @UVEnvironment(\.self)
    private var environment

    internal func _expandNode(_ node: Node, depth: Int) throws {
        print(environment)
    }
}

internal extension Element {
    var shortDescription: String {
        "\(type(of: self))"
    }
}

extension UltraviolenceError {
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
    func _dump() throws {
        let graph = try Graph(content: self)
        try graph.dump()
    }
}

@MainActor
internal extension Node {
    var shortDescription: String {
        self.element?.shortDescription ?? "<empty>"
    }
}
