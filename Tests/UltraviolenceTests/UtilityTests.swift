import Testing
@testable import Ultraviolence
import UltraviolenceSupport

// Test helper
struct TestDemoElement: Element, BodylessElement {
    typealias Body = Never
    var title: String

    init(_ title: String) {
        self.title = title
    }

    func expandIntoNode(_ node: Node, context: ExpansionContext) throws {
        // This line intentionally left blank.
    }
}

@Test
func isEqualTests() throws {
    struct NotEquatable {
    }
    #expect(isEqual(1, 1) == true)
    #expect(isEqual(0, 1) == false)
    #expect(isEqual(NotEquatable(), 1) == false)
    #expect(isEqual(1, NotEquatable()) == false)
    #expect(isEqual(NotEquatable(), NotEquatable()) == false)
}

@Test
@MainActor
func weirdTests() throws {
    let d = TestDemoElement("Nope")
    let any = AnyElement(d)
    let node = Node()
    #expect(throws: UltraviolenceError.noCurrentGraph) {
        try any.expandIntoNode(node, context: .init())
    }
}

@Test
@MainActor
func testOptionalElement() throws {
    let element = TestDemoElement("Hello world")
    let optionalElement = TestDemoElement?(element)
    let graph = try ElementGraph(content: optionalElement)
    try graph.rebuildIfNeeded()
    // Verify dump works without printing
    var dumpOutput = ""
    try graph.dump(to: &dumpOutput)
    #expect(!dumpOutput.isEmpty)
    #expect(graph.element(at: [], type: TestDemoElement.self).title == "Hello world")
}

@Test
@MainActor
func testElementDump() throws {
    let element = TestDemoElement("Hello world")
    var s = ""
    try element.dump(to: &s)
    s = s.trimmingCharacters(in: .whitespacesAndNewlines)
    #expect(s == "TestDemoElement")
}

@Test
@MainActor
func testGraphDump() throws {
    let root = TestDemoElement("Hello world")
    let graph = try ElementGraph(content: root)
    var s = ""
    try graph.dump(to: &s)
    s = s.trimmingCharacters(in: .whitespacesAndNewlines)
    #expect(s == "TestDemoElement")
}

@Test
@MainActor
func testComplexGraphDump() throws {
    let root = try Group {
        TestDemoElement("1")
        TestDemoElement("2")
        TestDemoElement("3")
        try Group {
            TestDemoElement("4")
            try Group {
                TestDemoElement("5")
            }
        }
    }
    let graph = try ElementGraph(content: root)
    var s = ""
    try graph.dump(options: [.dumpElement, .dumpNode], to: &s)
    s = s.trimmingCharacters(in: .whitespacesAndNewlines)
    // Verify the dump contains expected structure
    #expect(s.contains("TestDemoElement"))
    #expect(s.contains("Group"))
}

@Test
@MainActor
func testAnyElement() throws {
    let e = TestDemoElement("Hello world").eraseToAnyElement()
    let graph = try ElementGraph(content: e)
    try graph.rebuildIfNeeded()
    #expect(graph.element(at: [0], type: TestDemoElement.self).title == "Hello world")
}
