import Foundation
@testable import Ultraviolence
import Testing

@MainActor
struct UberTest {
    
    // MARK: - Test Elements
    
    struct RootElement: Element {
        @UVState var counter: Int = 0
        @UVEnvironment(\.exampleValue) var envValue
        
        var body: some Element {
            TrackedBodyless(name: "root", counter: counter, envValue: envValue)
            
            if counter > 0 {
                TrackedBodyless(name: "conditional", counter: counter * 10, envValue: envValue)
            }
            
            ChildElement(parentCounter: counter)
                .environment(\.exampleValue, "child-env")
        }
    }
    
    struct ChildElement: Element {
        let parentCounter: Int
        @UVEnvironment(\.exampleValue) var envValue
        
        var body: some Element {
            TrackedBodyless(name: "child", counter: parentCounter + 100, envValue: envValue)
            
            GrandchildElement(ancestorCounter: parentCounter + 100)
        }
    }
    
    struct GrandchildElement: Element {
        let ancestorCounter: Int
        @UVEnvironment(\.exampleValue) var envValue
        
        var body: some Element {
            TrackedBodyless(name: "grandchild", counter: ancestorCounter * 2, envValue: envValue)
        }
    }
    
    struct TrackedBodyless: Element, BodylessElement {
        let name: String
        let counter: Int
        let envValue: String
        
        var body: Never {
            fatalError()
        }
        
        func system_setupEnter(_ node: NeoNode) throws {
            TestMonitor.shared.record(phase: "setupEnter", element: name, counter: counter, env: envValue)
        }
        
        func system_setupExit(_ node: NeoNode) {
            TestMonitor.shared.record(phase: "setupExit", element: name, counter: counter, env: envValue)
        }
        
        func system_workloadEnter(_ node: NeoNode) throws {
            TestMonitor.shared.record(phase: "workloadEnter", element: name, counter: counter, env: envValue)
        }
        
        func system_workloadExit(_ node: NeoNode) {
            TestMonitor.shared.record(phase: "workloadExit", element: name, counter: counter, env: envValue)
        }
    }
    
    // MARK: - Tests
    
    @Test
    func testProcessOrderStateAndEnvironment() async throws {
        TestMonitor.shared.reset()
        
        let element = RootElement()
        let system = System()
        
        // Initial setup with counter=0
        try system.update(root: element)
        try system.processSetup()
        try system.processWorkload()
        
        let monitor = TestMonitor.shared
        
        // Verify process order: siblings complete before moving to next
        let calls = monitor.observations.map { "\($0.element)-\($0.phase)" }
        let expectedOrder = [
            // Setup: siblings complete before next
            "root-setupEnter",
            "root-setupExit",
            "child-setupEnter",
            "child-setupExit",
            "grandchild-setupEnter",
            "grandchild-setupExit",
            // Workload: siblings complete before next
            "root-workloadEnter",
            "root-workloadExit",
            "child-workloadEnter",
            "child-workloadExit",
            "grandchild-workloadEnter",
            "grandchild-workloadExit"
        ]
        #expect(calls == expectedOrder)
        
        // Verify state values
        let rootSetup = monitor.observations.first { $0.phase == "setupEnter" && $0.element == "root" }!
        #expect(rootSetup.counter == 0)
        #expect(rootSetup.env == "<default>")
        
        let childSetup = monitor.observations.first { $0.phase == "setupEnter" && $0.element == "child" }!
        #expect(childSetup.counter == 100) // 0 + 100
        #expect(childSetup.env == "child-env")
        
        let grandchildSetup = monitor.observations.first { $0.phase == "setupEnter" && $0.element == "grandchild" }!
        #expect(grandchildSetup.counter == 200) // (0 + 100) * 2
        #expect(grandchildSetup.env == "child-env")
        
        // Clear and test with state change
        monitor.reset()
        
        // Change state to add conditional element
        system.withCurrentSystem {
            element.counter = 1
        }
        
        #expect(!system.dirtyIdentifiers.isEmpty)
        
        try system.update(root: element)
        try system.processSetup()
        
        // Verify conditional element appears with correct values
        let conditionalSetup = monitor.observations.first { $0.phase == "setupEnter" && $0.element == "conditional" }!
        #expect(conditionalSetup.counter == 10) // 1 * 10
        #expect(conditionalSetup.env == "<default>")
        
        let childSetupAfter = monitor.observations.first { $0.phase == "setupEnter" && $0.element == "child" }!
        #expect(childSetupAfter.counter == 101) // 1 + 100
        #expect(childSetupAfter.env == "child-env")
        
        let grandchildSetupAfter = monitor.observations.first { $0.phase == "setupEnter" && $0.element == "grandchild" }!
        #expect(grandchildSetupAfter.counter == 202) // (1 + 100) * 2
        #expect(grandchildSetupAfter.env == "child-env")
    }
    
    @Test
    func testStateTimingDuringProcessing() async throws {
        struct TimingElement: Element {
            @UVState var value: Int = 0
            @UVState var capturedDuringSetup: Int = -1
            @UVState var capturedDuringWorkload: Int = -1
            
            var body: some Element {
                TimingBodyless(
                    value: value,
                    onSetup: { [self] in
                        capturedDuringSetup = value
                        value = 10
                    },
                    onWorkload: { [self] in  
                        capturedDuringWorkload = value
                        value = 20
                    }
                )
            }
        }
        
        struct TimingBodyless: Element, BodylessElement {
            let value: Int
            let onSetup: () -> Void
            let onWorkload: () -> Void
            
            var body: Never {
                fatalError()
            }
            
            func system_setupEnter(_ node: NeoNode) throws {
                onSetup()
            }
            
            func system_workloadEnter(_ node: NeoNode) throws {
                onWorkload()
            }
        }
        
        TestMonitor.shared.reset()
        
        let element = TimingElement()
        let system = System()
        
        try system.update(root: element)
        try system.processSetup()
        try system.processWorkload()
        
        // State mutations during processing are captured but don't affect the current cycle
        #expect(element.capturedDuringSetup == 0) // Sees initial value
        #expect(element.capturedDuringWorkload == 10) // Sees value after setup mutation
        #expect(element.value == 20) // Final value after both mutations
        
        // Next update cycle would see value=20
        try system.update(root: element)
        element.capturedDuringSetup = -1
        element.capturedDuringWorkload = -1
        try system.processSetup()
        
        #expect(element.capturedDuringSetup == 20) // Now sees the mutations from previous cycle
    }
    
    @Test
    func testEnvironmentPropagationTiming() async throws {
        struct EnvElement: Element {
            @UVState var modifier: String = "A"
            
            var body: some Element {
                EnvBodyless(name: "parent")
                    .environment(\.exampleValue, modifier)
                
                EnvBodyless(name: "child")
                    .environment(\.exampleValue, "\(modifier)-nested")
            }
        }
        
        struct EnvBodyless: Element, BodylessElement {
            let name: String
            @UVEnvironment(\.exampleValue) var envValue
            
            var body: Never {
                fatalError()
            }
            
            func system_setupEnter(_ node: NeoNode) throws {
                TestMonitor.shared.logUpdate("\(name): \(envValue)")
            }
        }
        
        TestMonitor.shared.reset()
        
        let element = EnvElement()
        let system = System()
        
        try system.update(root: element)
        try system.processSetup()
        
        let monitor = TestMonitor.shared
        
        // Initial environment values
        #expect(monitor.updates[0] == "parent: A")
        #expect(monitor.updates[1] == "child: A-nested")
        
        // Change state and verify environment updates
        monitor.reset()
        system.withCurrentSystem {
            element.modifier = "B"
        }
        
        try system.update(root: element)
        try system.processSetup()
        
        #expect(monitor.updates[0] == "parent: B")
        #expect(monitor.updates[1] == "child: B-nested")
    }
    
    @Test
    func testComplexHierarchy() async throws {
        struct ComplexElement: Element {
            @UVState var depth: Int = 2
            
            var body: some Element {
                SimpleTracked(name: "root")
                if depth > 0 {
                    RecursiveElement(depth: depth - 1)
                }
            }
        }
        
        struct RecursiveElement: Element {
            let depth: Int
            
            var body: some Element {
                SimpleTracked(name: "level-\(depth)")
                if depth > 0 {
                    RecursiveElement(depth: depth - 1)
                }
            }
        }
        
        struct SimpleTracked: Element, BodylessElement {
            let name: String
            
            var body: Never {
                fatalError()
            }
            
            func system_setupEnter(_ node: NeoNode) throws {
                TestMonitor.shared.record(phase: "setupEnter", element: name)
            }
            
            func system_setupExit(_ node: NeoNode) {
                TestMonitor.shared.record(phase: "setupExit", element: name)
            }
        }
        
        TestMonitor.shared.reset()
        
        let element = ComplexElement()
        let system = System()
        
        try system.update(root: element)
        try system.processSetup()
        
        let monitor = TestMonitor.shared
        let calls = monitor.observations.map { "\($0.element)-\($0.phase)" }
        
        // Should process siblings completely before moving to next sibling
        let expectedOrder = [
            "root-setupEnter",
            "root-setupExit",
            "level-1-setupEnter",
            "level-1-setupExit",
            "level-0-setupEnter",
            "level-0-setupExit"
        ]
        #expect(calls == expectedOrder)
    }
}