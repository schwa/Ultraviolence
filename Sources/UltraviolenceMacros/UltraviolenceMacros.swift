import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
public struct UltraviolenceMacros: CompilerPlugin {
    public let providingMacros: [Macro.Type] = [
        UVEntryMacro.self
    ]

    public init() {
        // This line intentionaly left blank.
    }
}
