import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(UltraviolenceMacros)
import UltraviolenceMacros

let testMacros: [String: Macro.Type] = [
    "Entry": UVEntryMacro.self
]
#endif

final class EntryMacroTests: XCTestCase {
    func testBasicType() throws {
        #if canImport(UltraviolenceMacros)
        assertMacroExpansion(
            """
            extension EnvironmentValues {
                @Entry
                var name: Int = 42
            }
            """,
            expandedSource:
                """
            extension EnvironmentValues {
                var name: Int {
                    get {
                        self[__Key_name.self]
                    }
                    set {
                        self[__Key_name.self] = newValue
                    }
                }

                private struct __Key_name: UVEnvironmentKey {
                    typealias Value = Int
                    static var defaultValue: Value {
                        42
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testOptionalType() throws {
        #if canImport(NotSwiftUIMacros)
        assertMacroExpansion(
            """
            extension EnvironmentValues {
                @Entry
                var name: String?
            }
            """,
            expandedSource:
                """
            extension EnvironmentValues {
                var name: String? {
                    get {
                        self[__Key_name.self]
                    }
                    set {
                        self[__Key_name.self] = newValue
                    }
                }

                private struct __Key_name: UVEnvironmentKey {
                    typealias Value = String?
                    static var defaultValue: Value {
                        nil
                    }
                }
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
}
