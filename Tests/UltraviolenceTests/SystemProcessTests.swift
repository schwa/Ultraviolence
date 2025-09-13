import Foundation
@testable import Ultraviolence
import Testing

@MainActor
struct SystemProcessTests {

    struct CallOrderTracker: Element, BodylessElement {
        var body: Never {
            fatalError()
        }
        
        func setupEnter(_ node: Node) throws {
            TestMonitor.shared.logUpdate("setupEnter")
        }
        
        func setupExit(_ node: Node) {
            TestMonitor.shared.logUpdate("setupExit")
        }
        
        func workloadEnter(_ node: Node) throws {
            TestMonitor.shared.logUpdate("workloadEnter")
        }
        
        func workloadExit(_ node: Node) {
            TestMonitor.shared.logUpdate("workloadExit")
        }
    }

    @Test
    func testSetupWorkloadOrder() async throws {
        TestMonitor.shared.reset()
        
        let element = CallOrderTracker()
        let system = System()
        
        try system.update(root: element)
        try system.processSetup()
        try system.processWorkload()
        
        #expect(TestMonitor.shared.updates == ["setupEnter", "setupExit", "workloadEnter", "workloadExit"])
    }
    
    struct TrackedBodyless: Element, BodylessElement {
        let name: String
        
        var body: Never {
            fatalError()
        }
        
        func setupEnter(_ node: Node) throws {
            TestMonitor.shared.logUpdate("\(name)-setupEnter")
        }
        
        func setupExit(_ node: Node) {
            TestMonitor.shared.logUpdate("\(name)-setupExit")
        }
        
        func workloadEnter(_ node: Node) throws {
            TestMonitor.shared.logUpdate("\(name)-workloadEnter")
        }
        
        func workloadExit(_ node: Node) {
            TestMonitor.shared.logUpdate("\(name)-workloadExit")
        }
    }
    
    struct DeepHierarchy: Element {
        var body: some Element {
            TrackedBodyless(name: "parent")
            Child1()
        }
        
        struct Child1: Element {
            var body: some Element {
                TrackedBodyless(name: "child1")
                Child2()
            }
        }
        
        struct Child2: Element {
            var body: some Element {
                TrackedBodyless(name: "child2-a")
                TrackedBodyless(name: "child2-b")
                Child3()
            }
        }
        
        struct Child3: Element {
            var body: some Element {
                TrackedBodyless(name: "child3")
            }
        }
    }
    
    @Test
    func testDeepHierarchyOrder() async throws {
        TestMonitor.shared.reset()
        
        let element = DeepHierarchy()
        let system = System()
        
        try system.update(root: element)
        try system.processSetup()
        try system.processWorkload()
        
        // Expected order explanation:
        // The new processing model ensures siblings complete (enter+exit) before moving to the next sibling.
        //
        // Actual element structure (siblings at each level):
        //   DeepHierarchy
        //   ├── parent (TrackedBodyless)
        //   └── Child1
        //       ├── child1 (TrackedBodyless)
        //       └── Child2
        //           ├── child2-a (TrackedBodyless)
        //           ├── child2-b (TrackedBodyless)
        //           └── Child3
        //               └── child3 (TrackedBodyless)
        //
        // Since all TrackedBodyless elements are siblings at their respective levels,
        // each completes (enter+exit) before the next sibling starts.
        //
        // Same pattern for both setup and workload phases
        let expectedSetupOrder = [
            "parent-setupEnter",
            "parent-setupExit",
            "child1-setupEnter",
            "child1-setupExit",
            "child2-a-setupEnter",
            "child2-a-setupExit",
            "child2-b-setupEnter",
            "child2-b-setupExit",
            "child3-setupEnter",
            "child3-setupExit",
            "parent-workloadEnter",
            "parent-workloadExit",
            "child1-workloadEnter",
            "child1-workloadExit",
            "child2-a-workloadEnter",
            "child2-a-workloadExit",
            "child2-b-workloadEnter",
            "child2-b-workloadExit",
            "child3-workloadEnter",
            "child3-workloadExit"
        ]
        
        #expect(TestMonitor.shared.updates == expectedSetupOrder)
    }
}
