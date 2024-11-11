import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct NotSwiftUIPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        EntryMacro.self
    ]
}
