import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct UVEntryMacro: AccessorMacro, PeerMacro {
    public static func expansion(of node: AttributeSyntax, providingAccessorsOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [AccessorDeclSyntax] {
        // NOTE: The real macro complains if we use it wrong: "'@Entry' macro can only attach to var declarations inside extensions of EnvironmentValues, Transaction, ContainerValues, or FocusedValues"
        guard let binding = declaration.as(VariableDeclSyntax.self)?.bindings.first else {
            return []
        }
        guard let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
            return []
        }
        return [
            """
        get {
            self[__Key_\(raw: name).self]
        }
        """,
            """
        set {
            self[__Key_\(raw: name).self] = newValue
        }
        """
        ]
    }

    public static func expansion(of node: AttributeSyntax, providingPeersOf declaration: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        guard let binding = declaration.as(VariableDeclSyntax.self)?.bindings.first else {
            return []
        }
        guard let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
            return []
        }
        guard let typeAnnotation = binding.typeAnnotation else {
            return []
        }
        let type = typeAnnotation.type
        let defaultValue = binding.initializer?.value ?? "nil"
        return [
            """
            private struct __Key_\(raw: name): UVEnvironmentKey {
                typealias Value = \(raw: type)
                static var defaultValue: Value { \(raw: defaultValue) }
            }
            """
        ]
    }
}
