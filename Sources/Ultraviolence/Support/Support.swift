internal import os
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
        // TODO: make rootEnvironment use default constructor.
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

internal struct TrivialID: Hashable, Sendable {
    private var rawValue: Int
    static let nextValue: OSAllocatedUnfairLock<Int> = .init(uncheckedState: 0)

    internal init() {
        rawValue = Self.nextValue.withLock { value in
            defer {
                value += 1
            }
            print("value: \(value)")
            return value
        }
    }
}

extension TrivialID: CustomDebugStringConvertible {
    var debugDescription: String {
        "#\(rawValue)"
    }
}
