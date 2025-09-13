import Testing
@testable import Ultraviolence

@Suite(.serialized)
@MainActor
struct OnChangeTests {
    struct TestElement: Element, BodylessElement {
        typealias Body = Never

        let value: String

        var body: Never {
            fatalError()
        }

        func workloadEnter(_ node: Node) throws {
            TestMonitor.shared.values["testValue"] = value
        }
    }

    @Test
    func testBasicOnChange() throws {
        TestMonitor.shared.reset()
        var changeCount = 0
        var lastOldValue: Int?
        var lastNewValue: Int?

        struct ContentElement: Element {
            @UVState var counter = 0
            let onCounterChange: (Int, Int) -> Void

            var body: some Element {
                TestElement(value: "Test-\(counter)")
                    .onChange(of: counter) { old, new in
                        onCounterChange(old, new)
                    }
            }
        }

        let element = ContentElement { old, new in
            changeCount += 1
            lastOldValue = old
            lastNewValue = new
        }

        let system = System()
        try system.update(root: element)
        try system.processSetup()

        // Initial setup should not trigger onChange by default
        #expect(changeCount == 0)
        #expect(lastOldValue == nil)
        #expect(lastNewValue == nil)

        // Change the value
        system.withCurrentSystem {
            element.counter = 1
        }
        try system.update(root: element)
        try system.processSetup()

        // onChange should have been called
        #expect(changeCount == 1)
        #expect(lastOldValue == 0)
        #expect(lastNewValue == 1)

        // Change the value again
        system.withCurrentSystem {
            element.counter = 5
        }
        try system.update(root: element)
        try system.processSetup()

        #expect(changeCount == 2)
        #expect(lastOldValue == 1)
        #expect(lastNewValue == 5)
    }

    @Test
    func testOnChangeWithInitial() throws {
        TestMonitor.shared.reset()
        var changeCount = 0
        var lastOldValue: Int?
        var lastNewValue: Int?

        struct ContentElement: Element {
            let initialValue: Int
            let onChange: (Int, Int) -> Void

            var body: some Element {
                TestElement(value: "Test-\(initialValue)")
                    .onChange(of: initialValue, initial: true) { old, new in
                        onChange(old, new)
                    }
            }
        }

        let element = ContentElement(initialValue: 42) { old, new in
            changeCount += 1
            lastOldValue = old
            lastNewValue = new
        }

        let system = System()
        try system.update(root: element)
        try system.processSetup()

        // Initial setup should trigger onChange when initial: true
        #expect(changeCount == 1)
        #expect(lastOldValue == 42)
        #expect(lastNewValue == 42)

        // Update with different value requires recreating the element
        let element2 = ContentElement(initialValue: 100) { old, new in
            changeCount += 1
            lastOldValue = old
            lastNewValue = new
        }

        try system.update(root: element2)
        try system.processSetup()

        #expect(changeCount == 2)
        #expect(lastOldValue == 42)
        #expect(lastNewValue == 100)
    }

    @Test
    func testOnChangeNoChangeWhenValueSame() throws {
        TestMonitor.shared.reset()
        var changeCount = 0

        struct ContentElement: Element {
            @UVState var value: String = "Hello"
            let onChange: () -> Void

            var body: some Element {
                TestElement(value: "Test")
                    .onChange(of: value) { _, _ in
                        onChange()
                    }
            }
        }

        let element = ContentElement {
            changeCount += 1
        }

        let system = System()
        try system.update(root: element)
        try system.processSetup()

        // Initial setup should not trigger onChange
        #expect(changeCount == 0)

        // Update with same value
        system.withCurrentSystem {
            element.value = "Hello"
        }
        try system.update(root: element)
        try system.processSetup()

        // Should not trigger for same value
        #expect(changeCount == 0)

        // Update with different value
        system.withCurrentSystem {
            element.value = "World"
        }
        try system.update(root: element)
        try system.processSetup()

        #expect(changeCount == 1)
    }

    @Test
    func testOnChangeSimpleAction() throws {
        TestMonitor.shared.reset()
        var actionCalled = false

        struct ContentElement: Element {
            @UVState var toggle = false
            let onToggle: () -> Void

            var body: some Element {
                TestElement(value: "Test-\(toggle)")
                    .onChange(of: toggle) {
                        onToggle()
                    }
            }
        }

        let element = ContentElement {
            actionCalled = true
        }

        let system = System()
        try system.update(root: element)
        try system.processSetup()

        // Initial setup should not trigger
        #expect(actionCalled == false)

        // Change the value
        system.withCurrentSystem {
            element.toggle = true
        }
        try system.update(root: element)
        try system.processSetup()

        #expect(actionCalled == true)
    }

    @Test
    func testMultipleOnChangeModifiers() throws {
        TestMonitor.shared.reset()
        var value1ChangeCount = 0
        var value2ChangeCount = 0

        struct ContentElement: Element {
            @UVState var value1 = 0
            @UVState var value2 = "A"
            let onValue1Change: () -> Void
            let onValue2Change: () -> Void

            var body: some Element {
                TestElement(value: "Test-\(value1)-\(value2)")
                    .onChange(of: value1) {
                        onValue1Change()
                    }
                    .onChange(of: value2) {
                        onValue2Change()
                    }
            }
        }

        let element = ContentElement(
            onValue1Change: { value1ChangeCount += 1 },
            onValue2Change: { value2ChangeCount += 1 }
        )

        let system = System()
        try system.update(root: element)
        try system.processSetup()

        #expect(value1ChangeCount == 0)
        #expect(value2ChangeCount == 0)

        // Change value1
        system.withCurrentSystem {
            element.value1 = 10
        }
        try system.update(root: element)
        try system.processSetup()

        #expect(value1ChangeCount == 1)
        #expect(value2ChangeCount == 0)

        // Change value2
        system.withCurrentSystem {
            element.value2 = "B"
        }
        try system.update(root: element)
        try system.processSetup()

        #expect(value1ChangeCount == 1)
        #expect(value2ChangeCount == 1)

        // Change both
        system.withCurrentSystem {
            element.value1 = 20
            element.value2 = "C"
        }
        try system.update(root: element)
        try system.processSetup()

        #expect(value1ChangeCount == 2)
        #expect(value2ChangeCount == 2)
    }

    @Test
    func testOnChangeWithBinding() throws {
        TestMonitor.shared.reset()
        var changeCount = 0
        var lastValue: Int?

        struct ChildElement: Element {
            @UVBinding var boundValue: Int
            let onChange: (Int) -> Void

            var body: some Element {
                TestElement(value: "Child-\(boundValue)")
                    .onChange(of: boundValue) { _, new in
                        onChange(new)
                    }
            }
        }

        struct ParentElement: Element {
            @UVState var value = 5
            let onChange: (Int) -> Void

            var body: some Element {
                ChildElement(boundValue: $value, onChange: onChange)
            }
        }

        let element = ParentElement { newValue in
            changeCount += 1
            lastValue = newValue
        }

        let system = System()
        try system.update(root: element)
        try system.processSetup()

        #expect(changeCount == 0)

        // Change through parent
        system.withCurrentSystem {
            element.value = 10
        }
        try system.update(root: element)
        try system.processSetup()

        #expect(changeCount == 1)
        #expect(lastValue == 10)

        // Change again
        system.withCurrentSystem {
            element.value = 15
        }
        try system.update(root: element)
        try system.processSetup()

        #expect(changeCount == 2)
        #expect(lastValue == 15)
    }

    @Test
    func testOnChangeOnlyCalledWhenValueChanges() throws {
        TestMonitor.shared.reset()
        var callCount = 0

        struct TrackedElement: Element {
            @UVState var value = 0
            let onValueChange: () -> Void

            var body: some Element {
                TestElement(value: "\(value)")
                    .onChange(of: value) { _, _ in
                        onValueChange()
                    }
            }
        }

        let element = TrackedElement {
            callCount += 1
        }

        let system = System()
        try system.update(root: element)
        try system.processSetup()

        // No call on initial setup
        #expect(callCount == 0)

        // Change to new value
        system.withCurrentSystem {
            element.value = 1
        }
        try system.update(root: element)
        try system.processSetup()
        #expect(callCount == 1)

        // Set to same value - no change
        system.withCurrentSystem {
            element.value = 1
        }
        try system.update(root: element)
        try system.processSetup()
        #expect(callCount == 1) // Should still be 1

        // Change to different value
        system.withCurrentSystem {
            element.value = 2
        }
        try system.update(root: element)
        try system.processSetup()
        #expect(callCount == 2)
    }
}
