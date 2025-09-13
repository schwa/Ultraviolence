import Foundation
import Testing
@testable import Ultraviolence

@MainActor
struct BindingTests {
    // MARK: - Basic Binding Test

    struct ParentWithBinding: Element {
        @UVState var value = 0

        var body: some Element {
            ChildWithBinding(value: $value)
        }
    }

    struct ChildWithBinding: Element {
        @UVBinding var value: Int

        var body: some Element {
            ActionElement(value: value) {
                value += 1
            }
        }
    }

    struct ActionElement: Element, BodylessElement {
        let value: Int
        let action: () -> Void

        var body: Never {
            fatalError()
        }

        func workloadEnter(_ node: Node) throws {
            TestMonitor.shared.values["value"] = value
        }
    }

    @Test
    func testBasicBinding() throws {
        TestMonitor.shared.reset()

        let root = ParentWithBinding()
        let system = System()

        try system.update(root: root)
        try system.processWorkload()

        // Initial value
        #expect(TestMonitor.shared.values["value"] as? Int == 0)

        // Modify through binding
        let actionElement = system.element(at: [0, 0, 0], type: ActionElement.self)!
        system.withCurrentSystem {
            actionElement.action()
        }

        try system.update(root: root)
        try system.processWorkload()

        // Value should be updated in parent
        #expect(root.value == 1)
        #expect(TestMonitor.shared.values["value"] as? Int == 1)
    }

    // MARK: - Two-Way Binding Test

    struct TwoWayParent: Element {
        @UVState var counter = 10

        var body: some Element {
            ActionElement(value: counter) {
                counter += 5
            }
            TwoWayChild(counter: $counter)
        }
    }

    struct TwoWayChild: Element {
        @UVBinding var counter: Int

        var body: some Element {
            ActionElement(value: counter) {
                counter *= 2
            }
        }
    }

    @Test
    func testTwoWayBinding() throws {
        TestMonitor.shared.reset()

        let root = TwoWayParent()
        let system = System()

        try system.update(root: root)

        // Modify from parent
        let parentAction = system.element(at: [0, 0, 0], type: ActionElement.self)!
        system.withCurrentSystem {
            parentAction.action()
        }

        try system.update(root: root)
        #expect(root.counter == 15)

        // Modify from child (through binding)
        let childAction = system.element(at: [0, 0, 1, 0], type: ActionElement.self)!
        system.withCurrentSystem {
            childAction.action()
        }

        try system.update(root: root)
        #expect(root.counter == 30)
    }

    // MARK: - Nested Bindings Test

    struct NestedBindingRoot: Element {
        @UVState var value = 100

        var body: some Element {
            NestedBindingMiddle(value: $value)
        }
    }

    struct NestedBindingMiddle: Element {
        @UVBinding var value: Int

        var body: some Element {
            NestedBindingLeaf(value: _value)
        }
    }

    struct NestedBindingLeaf: Element {
        @UVBinding var value: Int

        var body: some Element {
            ActionElement(value: value) {
                value -= 10
            }
        }
    }

    @Test
    func testNestedBindings() throws {
        TestMonitor.shared.reset()

        let root = NestedBindingRoot()
        let system = System()

        try system.update(root: root)
        try system.processWorkload()

        #expect(TestMonitor.shared.values["value"] as? Int == 100)

        // Modify at leaf level
        let leaf = system.element(at: [0, 0, 0, 0], type: ActionElement.self)!
        system.withCurrentSystem {
            leaf.action()
        }

        try system.update(root: root)
        try system.processWorkload()

        // Change should propagate all the way to root
        #expect(root.value == 90)
        #expect(TestMonitor.shared.values["value"] as? Int == 90)
    }

    // MARK: - Multiple Bindings Test

    struct MultiBindingParent: Element {
        @UVState var x = 1
        @UVState var y = 2
        @UVState var z = 3

        var body: some Element {
            MultiBindingChild(x: $x, y: $y, z: $z)
        }
    }

    struct MultiBindingChild: Element {
        @UVBinding var x: Int
        @UVBinding var y: Int
        @UVBinding var z: Int

        var body: some Element {
            CombinedElement(sum: x + y + z) {
                x *= 2
                y *= 3
                z *= 4
            }
        }
    }

    struct CombinedElement: Element, BodylessElement {
        let sum: Int
        let action: () -> Void

        var body: Never {
            fatalError()
        }

        func workloadEnter(_ node: Node) throws {
            TestMonitor.shared.values["sum"] = sum
        }
    }

    @Test
    func testMultipleBindings() throws {
        TestMonitor.shared.reset()

        let root = MultiBindingParent()
        let system = System()

        try system.update(root: root)
        try system.processWorkload()

        // Initial sum: 1 + 2 + 3 = 6
        #expect(TestMonitor.shared.values["sum"] as? Int == 6)

        // Trigger combined action
        let combined = system.element(at: [0, 0, 0], type: CombinedElement.self)!
        system.withCurrentSystem {
            combined.action()
        }

        try system.update(root: root)
        try system.processWorkload()

        // After: x=2, y=6, z=12, sum=20
        #expect(root.x == 2)
        #expect(root.y == 6)
        #expect(root.z == 12)
        #expect(TestMonitor.shared.values["sum"] as? Int == 20)
    }
}
