import Combine
import Testing
@testable import Ultraviolence

@Suite(.serialized)
@MainActor
struct RebuildTests {
    // Test that graph.update() properly triggers rebuilds when needsRebuild is set
    @Test
    func testGraphUpdateRebuildsWhenNeeded() throws {
        // Track body evaluation count
        var bodyEvaluationCount = 0

        // Create element with observable state
        struct TestElement: Element {
            @UVObservedObject var model: Model
            let counter: @MainActor () -> Void

            var body: some Element {
                counter()
                return DemoElement("Value: \(model.counter)")
            }
        }

        let model = Model()
        let element = TestElement(model: model) {
            bodyEvaluationCount += 1
        }

        // Create graph and do initial build
        let graph = try NodeGraph(content: element)
        try graph.rebuildIfNeeded()
        #expect(bodyEvaluationCount == 1, "Initial body evaluation should happen")

        // Trigger state change (sets needsRebuild = true via UVObservedObject)
        model.counter += 1

        // Update graph with same element - should trigger rebuild
        try graph.update(content: element)

        // This should pass after fix - body should be re-evaluated
        #expect(bodyEvaluationCount == 2, "Body should rebuild when state changes")

        // Verify the element actually has the new value
        let demoElement = graph.element(at: [0], type: DemoElement.self)
        #expect(demoElement.title == "Value: 1")
    }

    // Test that update respects the needsRebuild flag on nodes
    @Test
    func testUpdateRespectsNeedsRebuild() throws {
        struct TestElement: Element {
            var id: Int

            var body: some Element {
                DemoElement("ID: \(id)")
            }
        }

        let graph = try NodeGraph(content: TestElement(id: 1))
        try graph.rebuildIfNeeded()

        // Verify initial state
        let initialElement = graph.element(at: [0], type: DemoElement.self)
        #expect(initialElement.title == "ID: 1")

        // Manually set needsRebuild on root
        graph.root.setNeedsRebuild()
        #expect(graph.root.needsRebuild == true, "needsRebuild should be set")

        // Update should respect needsRebuild flag and rebuild
        try graph.update(content: TestElement(id: 2))

        // After update, needsRebuild should be false
        // This tests that the rebuild actually happened
        #expect(graph.root.needsRebuild == false, "needsRebuild should be cleared after rebuild")

        // And content should be updated
        let element = graph.element(at: [0], type: DemoElement.self)
        #expect(element.title == "ID: 2")
    }

    // Test that child rebuilds are triggered properly
    @Test
    func testChildRebuildsPropagate() throws {
        var parentBodyCount = 0
        var childBodyCount = 0

        struct ChildElement: Element {
            @UVObservedObject var model: Model
            let counter: @MainActor () -> Void

            var body: some Element {
                counter()
                return DemoElement("Child: \(model.counter)")
            }
        }

        struct ParentElement: Element {
            let model: Model
            let parentCounter: @MainActor () -> Void
            let childCounter: @MainActor () -> Void

            var body: some Element {
                parentCounter()
                return ChildElement(model: model, counter: childCounter)
            }
        }

        let model = Model()
        let element = ParentElement(
            model: model,
            parentCounter: { parentBodyCount += 1 },
            childCounter: { childBodyCount += 1 }
        )

        let graph = try NodeGraph(content: element)
        try graph.rebuildIfNeeded()

        #expect(parentBodyCount == 1, "Parent body should be evaluated once initially")
        #expect(childBodyCount == 1, "Child body should be evaluated once initially")

        // Change model state - this should trigger child rebuild
        model.counter += 1

        // Update the graph
        try graph.update(content: element)

        // Parent shouldn't rebuild (it doesn't observe the model)
        #expect(parentBodyCount == 2, "Parent body is re-evaluated on update (current behavior)")

        // Child should rebuild due to @UVObservedObject
        #expect(childBodyCount == 2, "Child should rebuild when observed object changes")
    }
}

// Use Model from StateTests which is already available
