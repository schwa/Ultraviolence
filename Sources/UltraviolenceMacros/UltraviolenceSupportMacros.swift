import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
public struct UltraviolenceMacros: CompilerPlugin {
    public let providingMacros: [Macro.Type] = [
        StringifyMacro.self,
        UUIDMacro.self
    ]

    public init() {
        // This line intentionaly left blank.
    }
}
