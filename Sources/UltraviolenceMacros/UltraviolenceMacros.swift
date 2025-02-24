import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
public struct UltraviolenceMacros: CompilerPlugin {
    public let providingMacros: [Macro.Type] = [
        UUIDMacro.self,
        MetaEnumMacro.self,
        UVEntryMacro.self
    ]

    public init() {
        // This line intentionaly left blank.
    }
}
