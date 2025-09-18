import Foundation
import Testing
@testable import Ultraviolence

@Suite("System Snapshot Tests")
struct SystemSnapshotTests {
    // Test element for snapshot testing
    struct TestElement: Element {
        @UVState var counter: Int = 0

        var body: some Element {
            EmptyElement()
        }
    }

    struct ParentElement: Element {
        @UVState var name: String = "Parent"

        var body: some Element {
            TestElement()
            TestElement()
        }
    }

    @Test("Create basic snapshot")
    @MainActor
    func testBasicSnapshot() throws {
        let system = System()
        let root = ParentElement()

        try system.update(root: root)

        let snapshot = system.snapshot()

        // Verify snapshot was created
        #expect(!snapshot.nodes.isEmpty)
        #expect(snapshot.timestamp.timeIntervalSinceNow < 1) // Recent timestamp
    }

    @Test("Snapshot captures node hierarchy")
    @MainActor
    func testNodeHierarchy() throws {
        let system = System()
        let root = ParentElement()

        try system.update(root: root)

        let snapshot = system.snapshot()

        // Should have parent and children
        #expect(snapshot.nodes.count == 6) // 1 parent + 2 children

        // Find parent node
        let parentNode = snapshot.nodes.first { $0.elementType.contains("ParentElement") }
        #expect(parentNode != nil)
        #expect(parentNode?.parentIdentifier == nil) // Root has no parent

        // Find child nodes
        let childNodes = snapshot.nodes.filter { $0.elementType.contains("TestElement") }
        #expect(childNodes.count == 3)

        // Find the TupleElement (which is the actual parent of TestElements)
        let tupleNode = snapshot.nodes.first { $0.elementType.contains("TupleElement") }
        #expect(tupleNode != nil)
        #expect(tupleNode?.parentIdentifier == parentNode?.identifier)

        // TestElement nodes should reference the TupleElement as parent
        for child in childNodes.filter({ $0.elementType == "TestElement" }) {
            #expect(child.parentIdentifier == tupleNode?.identifier)
        }
    }

    @Test("Snapshot captures state properties")
    @MainActor
    func testStateCapture() throws {
        let system = System()
        let root = TestElement()

        try system.update(root: root)

        let snapshot = system.snapshot()

        // Find the test element node
        let node = snapshot.nodes.first { $0.elementType.contains("TestElement") }
        #expect(node != nil)

        // Should have captured the counter state
        let counterState = node?.stateProperties.first { $0.key == "_counter" || $0.key == "counter" }
        #expect(counterState != nil)
        #expect(counterState?.value.contains("0") == true) // Initial value is 0
    }

    @Test("Codable works")
    @MainActor
    func testCodable() throws {
        let system = System()
        let root = ParentElement()

        try system.update(root: root)

        let snapshot = system.snapshot()

        // Test encoding
        let encoder = JSONEncoder()
        let data = try encoder.encode(snapshot)
        #expect(!data.isEmpty)

        // Test decoding
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SystemSnapshot.self, from: data)
        #expect(decoded.nodes.count == snapshot.nodes.count)
    }

    @Test("Text dump works")
    @MainActor
    func testTextDump() throws {
        let system = System()
        let root = ParentElement()

        try system.update(root: root)

        let snapshot = system.snapshot()
        let dump = snapshot.textDump()

        #expect(dump.contains("SYSTEM SNAPSHOT"))
        #expect(dump.contains("NODE HIERARCHY"))
        #expect(dump.contains("ParentElement"))
        #expect(dump.contains("TestElement"))
    }

    @Test("System dump method")
    @MainActor
    func testSystemDump() throws {
        let system = System()
        let root = TestElement()

        try system.update(root: root)

        // Test that dump doesn't crash (output goes to console)
        system.dump()
        system.dump(includeEnvironment: true)

        // Just verify we can create a snapshot
        let snapshot = system.snapshot()
        #expect(!snapshot.nodes.isEmpty)
    }

    @Test("Snapshot with environment values")
    @MainActor
    func testEnvironmentSnapshot() throws {
        struct EnvElement: Element {
            var body: some Element {
                EmptyElement()
            }
        }

        let system = System()
        let root = EnvElement()

        try system.update(root: root)

        let snapshot = system.snapshot()
        let dump = snapshot.textDump(includeEnvironment: true)

        #expect(dump.contains("Environment"))
        // The environment values should be captured
        #expect(!snapshot.nodes.isEmpty)
    }
}
