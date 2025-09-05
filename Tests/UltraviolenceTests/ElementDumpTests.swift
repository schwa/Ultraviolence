import Testing
@testable import Ultraviolence

struct ElementDumpTests {
    struct SimpleElement: Element {
        var body: some Element {
            EmptyElement()
        }
    }

    struct ContainerElement: Element {
        var body: some Element {
            SimpleElement()
            SimpleElement()
        }
    }

    struct ForEachExample: Element {
        var body: some Element {
            ForEach(["A", "B", "C"], id: \.self) { _ in
                SimpleElement()
            }
        }
    }

    @Test
    @MainActor
    func testSimpleDump() throws {
        let element = SimpleElement()
        let dump = try element.dump()
        #expect(dump.contains("SimpleElement"))
        #expect(dump.contains("EmptyElement"))
    }

    @Test
    @MainActor
    func testContainerDump() throws {
        let element = ContainerElement()
        let dump = try element.dump()
        #expect(dump.contains("ContainerElement"))
        #expect(dump.contains("TupleElement"))
        #expect(dump.contains("SimpleElement"))
    }

    @Test
    @MainActor
    func testForEachDump() throws {
        let element = ForEachExample()
        let dump = try element.dump()
        #expect(dump.contains("ForEachExample"))
        #expect(dump.contains("ForEach"))
        #expect(dump.contains("SimpleElement"))
    }

    @Test
    @MainActor
    func testVerboseDump() throws {
        let element = ContainerElement()
        let dump = try element.dumpVerbose()
        #expect(dump.contains("bodyless: false"))  // ContainerElement has a body
        #expect(dump.contains("bodyless: true"))   // TupleElement is bodyless
    }
}
