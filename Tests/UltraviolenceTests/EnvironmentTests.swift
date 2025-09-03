import Testing
@testable import Ultraviolence
import UltraviolenceSupport

extension UVEnvironmentValues {
    @UVEntry
    var exampleValue: String = ""
}

@Suite
@MainActor
struct EnvironmentTests {
    
    @Test
    func testEnvironment1() throws {
        struct Example1: Element {
            var body: some Element {
                EnvironmentReader(keyPath: \.exampleValue) { Example2(value: $0) }
                    .environment(\.exampleValue, "Hello world")
            }
        }

        struct Example2: Element, BodylessElement {
            typealias Body = Never
            var value: String
            func expandIntoNode(_ node: Node, context: ExpansionContext) throws {
            }
        }

        let s = Example1()
        let graph = try ElementGraph(content: s)
        try graph.rebuildIfNeeded()
        #expect(graph.element(at: [0], type: Example2.self).value == "Hello world")
    }

    @Test
    func testEnvironment2() throws {
        struct Example1: Element {
            var body: some Element {
                Example2()
                    .environment(\.exampleValue, "Hello world")
            }
        }

        struct Example2: Element {
            @UVEnvironment(\.exampleValue)
            var value
            var body: some Element {
                Example3(value: value)
            }
        }

        struct Example3: Element, BodylessElement {
            typealias Body = Never
            var value: String
            func expandIntoNode(_ node: Node, context: ExpansionContext) throws {
            }
        }

        let g1 = try ElementGraph(content: Example1())
        try g1.rebuildIfNeeded()
        #expect(g1.element(at: [0, 0], type: Example3.self).value == "Hello world")
    }
}