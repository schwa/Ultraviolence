import Testing
@testable import Ultraviolence

@Suite(.serialized)
@MainActor
struct OnChangeTests {
    struct TestElement: Element, BodylessElement {
        typealias Body = Never
        
        let value: String
        
        func expandIntoNode(_ node: Node, context: ExpansionContext) throws {
            // Empty implementation for test
        }
    }
    
    @Test
    func testBasicOnChange() throws {
        var changeCount = 0
        var lastOldValue: Int?
        var lastNewValue: Int?
        
        struct ContentElement: Element {
            @UVState var counter = 0
            let onCounterChange: (Int, Int) -> Void
            
            var body: some Element {
                TestElement(value: "Test")
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
        
        let graph = try ElementGraph(content: element)
        try graph.rebuildIfNeeded()
        try graph.processSetup()
        
        // Initial setup should not trigger onChange by default
        #expect(changeCount == 0)
        #expect(lastOldValue == nil)
        #expect(lastNewValue == nil)
        
        // Change the value
        let contentElement = graph.root.element as? ContentElement
        contentElement?.counter = 1
        try graph.rebuildIfNeeded()
        try graph.processSetup()
        
        // onChange should have been called
        #expect(changeCount == 1)
        #expect(lastOldValue == 0)
        #expect(lastNewValue == 1)
        
        // Change the value again
        contentElement?.counter = 5
        try graph.rebuildIfNeeded()
        try graph.processSetup()
        
        #expect(changeCount == 2)
        #expect(lastOldValue == 1)
        #expect(lastNewValue == 5)
    }
    
    @Test
    func testOnChangeWithInitial() throws {
        var changeCount = 0
        var lastOldValue: Int?
        var lastNewValue: Int?
        
        struct ContentElement: Element {
            let initialValue: Int
            let onChange: (Int, Int) -> Void
            
            var body: some Element {
                TestElement(value: "Test")
                    .onChange(of: initialValue, initial: true) { old, new in
                        onChange(old, new)
                    }
            }
        }
        
        var element = ContentElement(initialValue: 42) { old, new in
            changeCount += 1
            lastOldValue = old
            lastNewValue = new
        }
        let graph = try ElementGraph(content: element)
        try graph.rebuildIfNeeded()
        try graph.processSetup()
        
        // Initial setup should trigger onChange when initial: true
        #expect(changeCount == 1)
        #expect(lastOldValue == 42)
        #expect(lastNewValue == 42)
        
        // Update with same value
        element = ContentElement(initialValue: 42) { old, new in
            changeCount += 1
            lastOldValue = old
            lastNewValue = new
        }
        try graph.update(content: element)
        try graph.rebuildIfNeeded()
        try graph.processSetup()
        
        // Should not trigger again for same value
        #expect(changeCount == 1)
        
        // Update with different value
        element = ContentElement(initialValue: 100) { old, new in
            changeCount += 1
            lastOldValue = old
            lastNewValue = new
        }
        try graph.update(content: element)
        try graph.rebuildIfNeeded()
        try graph.processSetup()
        
        #expect(changeCount == 2)
        #expect(lastOldValue == 42)
        #expect(lastNewValue == 100)
    }
    
    @Test
    func testOnChangeNoChangeWhenValueSame() throws {
        var changeCount = 0
        
        struct ContentElement: Element {
            let value: String
            let onChange: () -> Void
            
            var body: some Element {
                TestElement(value: "Test")
                    .onChange(of: value) { _, _ in
                        onChange()
                    }
            }
        }
        
        var element = ContentElement(value: "Hello") {
            changeCount += 1
        }
        let graph = try ElementGraph(content: element)
        try graph.rebuildIfNeeded()
        try graph.processSetup()
        
        // Initial setup should not trigger onChange
        #expect(changeCount == 0)
        
        // Update with same value
        element = ContentElement(value: "Hello") {
            changeCount += 1
        }
        try graph.update(content: element)
        try graph.rebuildIfNeeded()
        try graph.processSetup()
        
        // Should not trigger for same value
        #expect(changeCount == 0)
        
        // Update with different value
        element = ContentElement(value: "World") {
            changeCount += 1
        }
        try graph.update(content: element)
        try graph.rebuildIfNeeded()
        try graph.processSetup()
        
        #expect(changeCount == 1)
    }
    
    @Test
    func testOnChangeSimpleAction() throws {
        var actionCalled = false
        
        struct ContentElement: Element {
            @UVState var toggle = false
            let onToggle: () -> Void
            
            var body: some Element {
                TestElement(value: "Test")
                    .onChange(of: toggle) {
                        onToggle()
                    }
            }
        }
        
        let element = ContentElement {
            actionCalled = true
        }
        
        let graph = try ElementGraph(content: element)
        try graph.rebuildIfNeeded()
        try graph.processSetup()
        
        // Initial setup should not trigger
        #expect(actionCalled == false)
        
        // Change the value
        let contentElement = graph.root.element as? ContentElement
        contentElement?.toggle = true
        try graph.rebuildIfNeeded()
        try graph.processSetup()
        
        #expect(actionCalled == true)
    }
    
    @Test
    func testMultipleOnChangeModifiers() throws {
        var value1ChangeCount = 0
        var value2ChangeCount = 0
        
        struct ContentElement: Element {
            @UVState var value1 = 0
            @UVState var value2 = "A"
            let onValue1Change: () -> Void
            let onValue2Change: () -> Void
            
            var body: some Element {
                TestElement(value: "Test")
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
        
        let graph = try ElementGraph(content: element)
        try graph.rebuildIfNeeded()
        try graph.processSetup()
        
        #expect(value1ChangeCount == 0)
        #expect(value2ChangeCount == 0)
        
        // Change value1
        let contentElement = graph.root.element as? ContentElement
        contentElement?.value1 = 10
        try graph.rebuildIfNeeded()
        try graph.processSetup()
        
        #expect(value1ChangeCount == 1)
        #expect(value2ChangeCount == 0)
        
        // Change value2
        contentElement?.value2 = "B"
        try graph.rebuildIfNeeded()
        try graph.processSetup()
        
        #expect(value1ChangeCount == 1)
        #expect(value2ChangeCount == 1)
        
        // Change both
        contentElement?.value1 = 20
        contentElement?.value2 = "C"
        try graph.rebuildIfNeeded()
        try graph.processSetup()
        
        #expect(value1ChangeCount == 2)
        #expect(value2ChangeCount == 2)
    }
    
    @Test
    func testOnChangeWithBinding() throws {
        var changeCount = 0
        var lastValue: Int?
        
        struct ChildElement: Element {
            @UVBinding var boundValue: Int
            let onChange: (Int) -> Void
            
            var body: some Element {
                TestElement(value: "Child")
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
        
        let graph = try ElementGraph(content: element)
        try graph.rebuildIfNeeded()
        try graph.processSetup()
        
        #expect(changeCount == 0)
        
        // Change through parent
        let parentElement = graph.root.element as? ParentElement
        parentElement?.value = 10
        try graph.rebuildIfNeeded()
        try graph.processSetup()
        
        #expect(changeCount == 1)
        #expect(lastValue == 10)
    }
}