import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
public struct UltraviolenceMacros: CompilerPlugin {
    public let providingMacros: [Macro.Type] = [
        StringifyMacro.self,
        UUIDMacro.self,
        MetaEnumMacro.self,
        EntryMacro.self
    ]

    public init() {
        // This line intentionaly left blank.
    }
}
