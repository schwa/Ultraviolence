import Testing
@testable import Ultraviolence

@Suite
struct SystemTests {
    // Simple test element for testing
    struct TestElement: Element {
        var value: Int
        var body: Never { fatalError() }
    }

    // Container element that has children
    struct ContainerElement: Element {
        var value: Int
        var childValue: Int

        var body: some Element {
            TestElement(value: childValue)
        }
    }

    // Container with multiple children
    struct MultiChildContainer: Element {
        var children: [Int]

        var body: some Element {
            ForEach(children, id: \.self) { value in
                TestElement(value: value)
            }
        }
    }

    @Test
    @MainActor
    func testSystemCreatesNodeForNewElement() throws {
        let system = System()
        let element = TestElement(value: 1)

        // Initial update should create a new node
        try system.update(root: element)

        // Should have one identifier for the root
        #expect(system.orderedIdentifiers.count == 1)

        // Should have one node
        #expect(system.nodes.count == 1)

        // Verify collections are equal and no duplicates
        #expect(Set(system.orderedIdentifiers) == Set(system.nodes.keys))
        #expect(system.orderedIdentifiers.count == Set(system.orderedIdentifiers).count) // No duplicates

        // Verify each node's id matches its key
        for id in system.orderedIdentifiers {
            #expect(system.nodes[id]?.id == id)
        }

        // The node should have the element
        let rootId = system.orderedIdentifiers[0]
        let node = system.nodes[rootId]
        #expect(node != nil)
        #expect(node?.id == rootId) // Node's id should match its key
        #expect((node?.element as? TestElement)?.value == 1)
    }

    @Test
    @MainActor
    func testSystemDetectsUnchangedElement() throws {
        let system = System()
        let element1 = TestElement(value: 1)

        // First update
        try system.update(root: element1)
        let node1 = system.nodes.values.first

        // Second update with same value
        let element2 = TestElement(value: 1)
        try system.update(root: element2)

        // Should still have one node
        #expect(system.nodes.count == 1)
        #expect(Set(system.orderedIdentifiers) == Set(system.nodes.keys))
        #expect(system.orderedIdentifiers.count == Set(system.orderedIdentifiers).count) // No duplicates

        // Verify each node's id matches its key
        for id in system.orderedIdentifiers {
            #expect(system.nodes[id]?.id == id)
        }

        // Node should be updated with new element
        let node2 = system.nodes.values.first
        #expect(node2?.id == node1?.id)
        #expect((node2?.element as? TestElement)?.value == 1)
    }

    @Test
    @MainActor
    func testSystemDetectsChangedElementValue() throws {
        let system = System()
        let element1 = TestElement(value: 1)

        // First update
        try system.update(root: element1)

        // Second update with different value
        let element2 = TestElement(value: 2)
        try system.update(root: element2)

        // Should still have same structural ID
        #expect(system.orderedIdentifiers.count == 1)
        #expect(Set(system.orderedIdentifiers) == Set(system.nodes.keys))
        #expect(system.orderedIdentifiers.count == Set(system.orderedIdentifiers).count) // No duplicates

        // Verify each node's id matches its key
        for id in system.orderedIdentifiers {
            #expect(system.nodes[id]?.id == id)
        }

        // But element should be updated
        let node = system.nodes.values.first
        #expect((node?.element as? TestElement)?.value == 2)
    }

    @Test
    @MainActor
    func testSystemHandlesNestedElements() throws {
        let system = System()
        let container = ContainerElement(value: 1, childValue: 10)

        // Initial update
        try system.update(root: container)

        // Should have 2 identifiers: container and its child
        #expect(system.orderedIdentifiers.count == 2)
        #expect(system.nodes.count == 2)
        #expect(Set(system.orderedIdentifiers) == Set(system.nodes.keys))
        #expect(system.orderedIdentifiers.count == Set(system.orderedIdentifiers).count) // No duplicates

        // Verify each node's id matches its key
        for id in system.orderedIdentifiers {
            #expect(system.nodes[id]?.id == id)
        }

        // Check the container node
        let containerId = system.orderedIdentifiers[0]
        let containerNode = system.nodes[containerId]
        #expect((containerNode?.element as? ContainerElement)?.value == 1)

        // Check the child node
        let childId = system.orderedIdentifiers[1]
        let childNode = system.nodes[childId]
        #expect((childNode?.element as? TestElement)?.value == 10)

        // Verify the structural path is correct
        // Container should have 1 atom (root)
        #expect(containerId.atoms.count == 1)
        // Child should have 2 atoms (container -> child)
        #expect(childId.atoms.count == 2)
    }

    @Test
    @MainActor
    func testSystemDetectsChildValueChange() throws {
        let system = System()

        // First update
        let container1 = ContainerElement(value: 1, childValue: 10)
        try system.update(root: container1)

        // Second update - only child value changes
        let container2 = ContainerElement(value: 1, childValue: 20)
        try system.update(root: container2)

        // Structure should be the same
        #expect(system.orderedIdentifiers.count == 2)
        #expect(Set(system.orderedIdentifiers) == Set(system.nodes.keys))
        #expect(system.orderedIdentifiers.count == Set(system.orderedIdentifiers).count) // No duplicates

        // Verify each node's id matches its key
        for id in system.orderedIdentifiers {
            #expect(system.nodes[id]?.id == id)
        }

        // Container should be updated but value unchanged
        let containerId = system.orderedIdentifiers[0]
        let containerNode = system.nodes[containerId]
        #expect((containerNode?.element as? ContainerElement)?.value == 1)

        // Child should show the value change
        let childId = system.orderedIdentifiers[1]
        let childNode = system.nodes[childId]
        #expect((childNode?.element as? TestElement)?.value == 20)
    }

    @Test
    @MainActor
    func testSystemDetectsStructuralChanges() throws {
        let system = System()

        // First update with 2 children
        let container1 = MultiChildContainer(children: [1, 2])
        try system.update(root: container1)

        // Should have: container + ForEach + 2 TestElements = 4 nodes
        #expect(system.orderedIdentifiers.count == 4)
        #expect(Set(system.orderedIdentifiers) == Set(system.nodes.keys))
        #expect(system.orderedIdentifiers.count == Set(system.orderedIdentifiers).count) // No duplicates

        // Verify each node's id matches its key
        for id in system.orderedIdentifiers {
            #expect(system.nodes[id]?.id == id)
        }

        // Second update with 3 children
        let container2 = MultiChildContainer(children: [1, 2, 3])
        try system.update(root: container2)

        // Should now have: container + ForEach + 3 TestElements = 5 nodes
        #expect(system.orderedIdentifiers.count == 5)
        #expect(Set(system.orderedIdentifiers) == Set(system.nodes.keys))
        #expect(system.orderedIdentifiers.count == Set(system.orderedIdentifiers).count) // No duplicates

        // Verify each node's id matches its key after update
        for id in system.orderedIdentifiers {
            #expect(system.nodes[id]?.id == id)
        }

        // The new child should be at the end
        let newChildId = system.orderedIdentifiers[4]
        let newChildNode = system.nodes[newChildId]
        #expect((newChildNode?.element as? TestElement)?.value == 3)
    }
}
