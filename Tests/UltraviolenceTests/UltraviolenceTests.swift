import Combine
import Testing
@testable import Ultraviolence
import UltraviolenceSupport

// TODO: Break this up into smaller files.

struct DemoElement: Element, BodylessElement {
    typealias Body = Never

    var title: String
    var action: () -> Void

    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    func _expandNode(_ node: Node, depth: Int) throws {
        // This line intentionally left blank.
    }
}


extension UVEnvironmentValues {
    @UVEntry
    var exampleValue: String = ""
}

final class Model: ObservableObject {
    @Published var counter: Int = 0
}

extension Element {
    func debug(_ f: () -> Void) -> some Element {
        f()
        return self
    }
}

struct ContentRenderPass: Element {
    @UVObservedObject var model = Model()
    var body: some Element {
        DemoElement("\(model.counter)") {
            model.counter += 1
        }
    }
}

@MainActor
var nestedModel = Model()

@MainActor
var nestedBodyCount = 0

@MainActor
var contentRenderPassBodyCount = 0

@MainActor
var sampleBodyCount = 0

@Suite(.serialized)
@MainActor
struct UltraviolenceStateTests {
    init() {
        nestedBodyCount = 0
        contentRenderPassBodyCount = 0
        nestedModel.counter = 0
        sampleBodyCount = 0
    }

    @Test
    func testUpdate() throws {
        let v = ContentRenderPass()

        let graph = try Graph(content: v)
        try graph.rebuildIfNeeded()
        var demoElement: DemoElement {
            graph.element(at: [0], type: DemoElement.self)
        }
        #expect(demoElement.title == "0")
        demoElement.action()
        try graph.rebuildIfNeeded()
        #expect(demoElement.title == "1")
    }

    // MARK: ObservedObject tests

    @Test
    func testConstantNested() throws {
        @MainActor struct Nested: Element {
            var body: some Element {
                nestedBodyCount += 1
                return DemoElement("Nested DemoElement") {}
            }
        }

        struct ContentRenderPass: Element {
            @UVObservedObject var model = Model()
            var body: some Element {
                DemoElement("\(model.counter)") {
                    model.counter += 1
                }
                Nested()
                    .debug {
                        contentRenderPassBodyCount += 1
                    }
            }
        }

        let v = ContentRenderPass()
        let graph = try Graph(content: v)
        try graph.rebuildIfNeeded()
        #expect(contentRenderPassBodyCount == 1)
        #expect(nestedBodyCount == 1)
        var demoElement: DemoElement {
            graph.element(at: [0, 0], type: DemoElement.self)
        }
        demoElement.action()
        try graph.rebuildIfNeeded()
        #expect(contentRenderPassBodyCount == 2)
        #expect(nestedBodyCount == 1)
    }

    @Test
    func testChangedNested() throws {
        struct Nested: Element {
            var counter: Int
            var body: some Element {
                nestedBodyCount += 1
                return DemoElement("Nested DemoElement") {}
            }
        }

        struct ContentRenderPass: Element {
            @UVObservedObject var model = Model()
            var body: some Element {
                DemoElement("\(model.counter)") {
                    model.counter += 1
                }
                Nested(counter: model.counter)
                    .debug {
                        contentRenderPassBodyCount += 1
                    }
            }
        }

        let v = ContentRenderPass()
        let graph = try Graph(content: v)
        try graph.rebuildIfNeeded()
        #expect(contentRenderPassBodyCount == 1)
        #expect(nestedBodyCount == 1)
        var demoElement: DemoElement {
            graph.element(at: [0, 0], type: DemoElement.self)
        }
        demoElement.action()
        try graph.rebuildIfNeeded()
        #expect(contentRenderPassBodyCount == 2)
        #expect(nestedBodyCount == 2)
    }

    @Test
    func testUnchangedNested() throws {
        struct Nested: Element {
            var isLarge: Bool = false
            var body: some Element {
                nestedBodyCount += 1
                return DemoElement("Nested DemoElement") {}
            }
        }

        struct ContentRenderPass: Element {
            @UVObservedObject var model = Model()
            var body: some Element {
                DemoElement("\(model.counter)") {
                    model.counter += 1
                }
                Nested(isLarge: model.counter > 10)
                    .debug {
                        contentRenderPassBodyCount += 1
                    }
            }
        }

        let v = ContentRenderPass()
        let graph = try Graph(content: v)
        try graph.rebuildIfNeeded()
        #expect(contentRenderPassBodyCount == 1)
        #expect(nestedBodyCount == 1)
        var demoElement: DemoElement {
            graph.element(at: [0, 0], type: DemoElement.self)
        }
        demoElement.action()
        try graph.rebuildIfNeeded()
        #expect(contentRenderPassBodyCount == 2)
        #expect(nestedBodyCount == 1)
    }

    @Test
    func testUnchangedNestedWithObservedObject() throws {
        struct Nested: Element {
            @UVObservedObject var model = nestedModel
            var body: some Element {
                nestedBodyCount += 1
                return DemoElement("Nested DemoElement") {}
            }
        }

        struct ContentRenderPass: Element {
            @UVObservedObject var model = Model()
            var body: some Element {
                DemoElement("\(model.counter)") {
                    model.counter += 1
                }
                Nested()
                    .debug {
                        contentRenderPassBodyCount += 1
                    }
            }
        }

        let v = ContentRenderPass()
        let graph = try Graph(content: v)
        try graph.rebuildIfNeeded()
        #expect(contentRenderPassBodyCount == 1)
        #expect(nestedBodyCount == 1)
        var demoElement: DemoElement {
            graph.element(at: [0, 0], type: DemoElement.self)
        }
        demoElement.action()
        try graph.rebuildIfNeeded()
        #expect(contentRenderPassBodyCount == 2)
        #expect(nestedBodyCount == 1)
    }

    @Test
    func testBinding1() throws {
        struct Nested: Element {
            @UVBinding var counter: Int
            var body: some Element {
                nestedBodyCount += 1
                return DemoElement("Nested DemoElement") {}
            }
        }

        struct ContentRenderPass: Element {
            @UVObservedObject var model = Model()
            var body: some Element {
                DemoElement("\(model.counter)") {
                    model.counter += 1
                }
                Nested(counter: $model.counter)
                    .debug {
                        contentRenderPassBodyCount += 1
                    }
            }
        }

        let v = ContentRenderPass()
        let graph = try Graph(content: v)
        try graph.rebuildIfNeeded()
        #expect(contentRenderPassBodyCount == 1)
        #expect(nestedBodyCount == 1)
        var demoElement: DemoElement {
            graph.element(at: [0, 0], type: DemoElement.self)
        }
        demoElement.action()
        try graph.rebuildIfNeeded()
        #expect(contentRenderPassBodyCount == 2)
        #expect(nestedBodyCount == 2)
    }

    @Test
    func testBinding2() throws {
        struct Nested: Element {
            @UVBinding var counter: Int
            var body: some Element {
                nestedBodyCount += 1
                return DemoElement("\(counter)") { counter += 1 }
            }
        }

        struct ContentRenderPass: Element {
            @UVObservedObject var model = Model()
            var body: some Element {
                Nested(counter: $model.counter)
                    .debug {
                        contentRenderPassBodyCount += 1
                    }
            }
        }

        let v = ContentRenderPass()
        let graph = try Graph(content: v)
        try graph.rebuildIfNeeded()
        var demoElement: DemoElement {
            graph.element(at: [0, 0], type: DemoElement.self)
        }
        #expect(contentRenderPassBodyCount == 1)
        #expect(nestedBodyCount == 1)
        #expect(demoElement.title == "0")
        demoElement.action()
        try graph.rebuildIfNeeded()
        #expect(contentRenderPassBodyCount == 2)
        #expect(nestedBodyCount == 2)
        #expect(demoElement.title == "1")
    }

    // MARK: State tests

    @Test
    func testSimple() throws {
        struct Nested: Element {
            @UVState private var counter = 0
            var body: some Element {
                DemoElement("\(counter)") {
                    counter += 1
                }
            }
        }

        struct Sample: Element {
            @UVState private var counter = 0
            var body: some Element {
                DemoElement("\(counter)") {
                    counter += 1
                }
                Nested()
            }
        }

        let s = Sample()
        let graph = try Graph(content: s)
        try graph.rebuildIfNeeded()
        var demoElement: DemoElement {
            graph.element(at: [0, 0], type: DemoElement.self)
        }
        var nestedDemoElement: DemoElement {
            graph.element(at: [0, 1, 0], type: DemoElement.self)
        }
        #expect(demoElement.title == "0")
        #expect(nestedDemoElement.title == "0")

        nestedDemoElement.action()
        try graph.rebuildIfNeeded()

        #expect(demoElement.title == "0")
        #expect(nestedDemoElement.title == "1")

        demoElement.action()
        try graph.rebuildIfNeeded()

        #expect(demoElement.title == "1")
        #expect(nestedDemoElement.title == "1")
    }

    @Test
    func testBindings() throws {
        struct Nested: Element {
            @UVBinding var counter: Int
            var body: some Element {
                DemoElement("\(counter)") {
                    counter += 1
                }
            }
        }

        struct Sample: Element {
            @UVState private var counter = 0
            var body: some Element {
                Nested(counter: $counter)
            }
        }

        let s = Sample()
        let graph = try Graph(content: s)
        try graph.rebuildIfNeeded()
        var nestedDemoElement: DemoElement {
            graph.element(at: [0, 0], type: DemoElement.self)
        }
        #expect(nestedDemoElement.title == "0")

        nestedDemoElement.action()
        try graph.rebuildIfNeeded()
        #expect(nestedDemoElement.title == "1")
    }

    @Test
    func testUnusedBinding() throws {
        struct Nested: Element {
            @UVBinding var counter: Int
            var body: some Element {
                DemoElement("") {
                    counter += 1
                }
                .debug { nestedBodyCount += 1 }
            }
        }

        struct Sample: Element {
            @UVState private var counter = 0
            var body: some Element {
                DemoElement("\(counter)") {}
                Nested(counter: $counter)
                    .debug { sampleBodyCount += 1 }
            }
        }

        let s = Sample()
        let graph = try Graph(content: s)
        try graph.rebuildIfNeeded()
        var nestedDemoElement: DemoElement {
            graph.element(at: [0, 1, 0], type: DemoElement.self)
        }
        #expect(sampleBodyCount == 1)
        #expect(nestedBodyCount == 1)

        nestedDemoElement.action()
        try graph.rebuildIfNeeded()

        #expect(sampleBodyCount == 2)
        #expect(nestedBodyCount == 1)
    }

    // Environment Tests

    @Test
    func testEnvironment1() throws {
        struct Example1: Element {
            var body: some Element {
                EnvironmentReader(keyPath: \.exampleValue) { Example2(value: $0) }
                    .environment(\.exampleValue, "Hello world")
            }
        }

        struct Example2: Element, BodylessElement {
            typealias Body = Never
            var value: String
            func _expandNode(_ node: Node, depth: Int) throws {
            }
        }

        let s = Example1()
        let graph = try Graph(content: s)
        try graph.rebuildIfNeeded()
        #expect(graph.element(at: [0], type: Example2.self).value == "Hello world")
    }

    @Test
    func testEnvironment2() throws {
        struct Example1: Element {
            var body: some Element {
                Example2()
                    .environment(\.exampleValue, "Hello world")
            }
        }

        struct Example2: Element {
            @UVEnvironment(\.exampleValue)
            var value
            var body: some Element {
                Example3(value: value)
            }
        }

        struct Example3: Element, BodylessElement {
            typealias Body = Never
            var value: String
            func _expandNode(_ node: Node, depth: Int) throws {
            }
        }

        let g1 = try Graph(content: Example1())
        try g1.rebuildIfNeeded()
        #expect(g1.element(at: [0, 0], type: Example3.self).value == "Hello world")
    }

 @Test
    func testAnyElement() throws {
        let e = DemoElement("Hello world", action: {}).eraseToAnyElement()
        let graph = try Graph(content: e)
        try graph.rebuildIfNeeded()
        #expect(graph.element(at: [0], type: DemoElement.self).title == "Hello world")
    }

    @Test
    func testModifier() throws {

        let root = DemoElement("Hello world", action: {}).modifier(PassthroughModifier())

        let graph = try Graph(content: root)
        try graph.rebuildIfNeeded()
//        #expect(graph.element(at: [0, 0, 0], type: Example3.self).value == "Hello world")

        try graph.dump()



    }

}
