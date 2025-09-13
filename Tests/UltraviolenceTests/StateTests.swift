import Foundation
import Testing
@testable import Ultraviolence

@MainActor
struct StateTests {
    // MARK: - Basic State Test

    struct TestRoot: Element {
        @UVState var count: Int = 0

        var body: some Element {
            TestChild(count: count)
        }
    }

    struct TestChild: Element {
        var count: Int

        init(count: Int) {
            self.count = count
        }

        var body: some Element {
            EmptyElement()
        }
    }

    @Test
    func testBasicStateMutation() throws {
        let root = TestRoot()
        let system = System()
        try system.update(root: root)

        #expect(system.dirtyIdentifiers.isEmpty)

        system.withCurrentSystem {
            root.count += 1
        }

        #expect(root.count == 1)
        #expect(system.dirtyIdentifiers.count == 1)

        try system.update(root: root)

        #expect(root.count == 1)
        #expect(system.dirtyIdentifiers.isEmpty)
    }

    // MARK: - Independent State Test

    struct ParentWithState: Element {
        @UVState var parentCounter = 0

        var body: some Element {
            TrackedElement(name: "parent", value: parentCounter) {
                parentCounter += 1
            }
            ChildWithState()
        }
    }

    struct ChildWithState: Element {
        @UVState var childCounter = 0

        var body: some Element {
            TrackedElement(name: "child", value: childCounter) {
                childCounter += 1
            }
        }
    }

    struct TrackedElement: Element, BodylessElement {
        let name: String
        let value: Int
        let action: () -> Void

        var body: Never {
            fatalError()
        }

        func workloadEnter(_ node: Node) throws {
            TestMonitor.shared.values[name] = value
        }
    }

    @Test
    func testIndependentStateInHierarchy() throws {
        TestMonitor.shared.reset()

        let root = ParentWithState()
        let system = System()

        try system.update(root: root)
        try system.processWorkload()

        // Initial values
        #expect(TestMonitor.shared.values["parent"] as? Int == 0)
        #expect(TestMonitor.shared.values["child"] as? Int == 0)

        // Get elements and trigger child action
        let childElement = system.element(at: [0, 0, 1, 0], type: TrackedElement.self)!
        system.withCurrentSystem {
            childElement.action()
        }

        // Only child should be dirty
        #expect(system.dirtyIdentifiers.count == 1)

        try system.update(root: root)
        try system.processWorkload()

        // Parent unchanged, child incremented
        #expect(TestMonitor.shared.values["parent"] as? Int == 0)
        #expect(TestMonitor.shared.values["child"] as? Int == 1)

        // Now trigger parent action
        let parentElement = system.element(at: [0, 0, 0], type: TrackedElement.self)!
        system.withCurrentSystem {
            parentElement.action()
        }

        try system.update(root: root)
        try system.processWorkload()

        // Parent incremented, child unchanged
        #expect(TestMonitor.shared.values["parent"] as? Int == 1)
        #expect(TestMonitor.shared.values["child"] as? Int == 1)
    }

    // MARK: - State Propagation Test

    struct PropagationRoot: Element {
        @UVState var value = 0

        var body: some Element {
            PropagationMiddle(parentValue: value) {
                value += 10
            }
        }
    }

    struct PropagationMiddle: Element {
        let parentValue: Int
        let onIncrement: () -> Void
        @UVState var ownValue = 100

        var body: some Element {
            PropagationLeaf(
                combinedValue: parentValue + ownValue
            )                {
                    onIncrement()
                    ownValue += 1
                }
        }
    }

    struct PropagationLeaf: Element, BodylessElement {
        let combinedValue: Int
        let onIncrement: () -> Void

        var body: Never {
            fatalError()
        }

        func workloadEnter(_ node: Node) throws {
            TestMonitor.shared.values["combined"] = combinedValue
        }
    }

    @Test
    func testStatePropagationThroughHierarchy() throws {
        TestMonitor.shared.reset()

        let root = PropagationRoot()
        let system = System()

        try system.update(root: root)
        try system.processWorkload()

        // Initial: parent=0, middle=100, combined=100
        #expect(TestMonitor.shared.values["combined"] as? Int == 100)

        // Trigger action
        let leaf = system.element(at: [0, 0, 0], type: PropagationLeaf.self)!
        system.withCurrentSystem {
            leaf.onIncrement()
        }

        try system.update(root: root)
        try system.processWorkload()

        // After: parent=10, middle=101, combined=111
        #expect(TestMonitor.shared.values["combined"] as? Int == 111)
    }
}
