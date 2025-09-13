//
//  EnvironmentReader.swift
//  Ultraviolence
//
//  Created by Jonathan Wight on 9/12/25.
//

public struct EnvironmentReader<Value, Content: Element>: Element, BodylessElement {
    var keyPath: KeyPath<UVEnvironmentValues, Value>
    var content: (Value) throws -> Content

    public init(keyPath: KeyPath<UVEnvironmentValues, Value>, @ElementBuilder content: @escaping (Value) throws -> Content) {
        self.keyPath = keyPath
        self.content = content
    }

    func visitChildrenBodyless(_ visit: (any Element) throws -> Void) throws {
        // TODO: Ideally we would be passed a Node as a parameter here... FILE THIS.
        guard let system = System.current, let node = system.activeNodeStack.last else {
            fatalError("EnvironmentReader must be visited within a System context, with a valid non-empty activeNodeStack.")
        }
        let value = node.environmentValues[keyPath: keyPath]
        let content = try content(value)
        try visit(content)
    }
}
