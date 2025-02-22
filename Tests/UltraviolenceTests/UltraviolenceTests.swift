import Combine
import Testing
@testable import Ultraviolence
import UltraviolenceSupport

// TODO: "Button" rename as "DemoElement" or something.
struct Button: Element, BodylessElement {
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
        Button("\(model.counter)") {
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
struct NotSwiftUIStateTests {
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
        var button: Button {
            graph.element(at: [0], type: Button.self)
        }
        #expect(button.title == "0")
        button.action()
        try graph.rebuildIfNeeded()
        #expect(button.title == "1")
    }

    // MARK: ObservedObject tests

    @Test
    func testConstantNested() throws {
        @MainActor struct Nested: Element {
            var body: some Element {
                nestedBodyCount += 1
                return Button("Nested Button") {}
            }
        }

        struct ContentRenderPass: Element {
            @UVObservedObject var model = Model()
            var body: some Element {
                Button("\(model.counter)") {
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
        var button: Button {
            graph.element(at: [0, 0], type: Button.self)
        }
        button.action()
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
                return Button("Nested Button") {}
            }
        }

        struct ContentRenderPass: Element {
            @UVObservedObject var model = Model()
            var body: some Element {
                Button("\(model.counter)") {
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
        var button: Button {
            graph.element(at: [0, 0], type: Button.self)
        }
        button.action()
        try graph.rebuildIfNeeded()
        #expect(contentRenderPassBodyCount == 2)
        #expect(nestedBodyCount == 2)
    }

    @Test func testUnchangedNested() throws {
        struct Nested: Element {
            var isLarge: Bool = false
            var body: some Element {
                nestedBodyCount += 1
                return Button("Nested Button") {}
            }
        }

        struct ContentRenderPass: Element {
            @UVObservedObject var model = Model()
            var body: some Element {
                Button("\(model.counter)") {
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
        var button: Button {
            graph.element(at: [0, 0], type: Button.self)
        }
        button.action()
        try graph.rebuildIfNeeded()
        #expect(contentRenderPassBodyCount == 2)
        #expect(nestedBodyCount == 1)
    }

    @Test func testUnchangedNestedWithObservedObject() throws {
        struct Nested: Element {
            @UVObservedObject var model = nestedModel
            var body: some Element {
                nestedBodyCount += 1
                return Button("Nested Button") {}
            }
        }

        struct ContentRenderPass: Element {
            @UVObservedObject var model = Model()
            var body: some Element {
                Button("\(model.counter)") {
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
        var button: Button {
            graph.element(at: [0, 0], type: Button.self)
        }
        button.action()
        try graph.rebuildIfNeeded()
        #expect(contentRenderPassBodyCount == 2)
        #expect(nestedBodyCount == 1)
    }

    @Test func testBinding1() throws {
        struct Nested: Element {
            @UVBinding var counter: Int
            var body: some Element {
                nestedBodyCount += 1
                return Button("Nested Button") {}
            }
        }

        struct ContentRenderPass: Element {
            @UVObservedObject var model = Model()
            var body: some Element {
                Button("\(model.counter)") {
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
        var button: Button {
            graph.element(at: [0, 0], type: Button.self)
        }
        button.action()
        try graph.rebuildIfNeeded()
        #expect(contentRenderPassBodyCount == 2)
        #expect(nestedBodyCount == 2)
    }

    @Test func testBinding2() throws {
        struct Nested: Element {
            @UVBinding var counter: Int
            var body: some Element {
                nestedBodyCount += 1
                return Button("\(counter)") { counter += 1 }
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
        var button: Button {
            graph.element(at: [0, 0], type: Button.self)
        }
        #expect(contentRenderPassBodyCount == 1)
        #expect(nestedBodyCount == 1)
        #expect(button.title == "0")
        button.action()
        try graph.rebuildIfNeeded()
        #expect(contentRenderPassBodyCount == 2)
        #expect(nestedBodyCount == 2)
        #expect(button.title == "1")
    }

    // MARK: State tests

    @Test func testSimple() throws {
        struct Nested: Element {
            @UVState private var counter = 0
            var body: some Element {
                Button("\(counter)") {
                    counter += 1
                }
            }
        }

        struct Sample: Element {
            @UVState private var counter = 0
            var body: some Element {
                Button("\(counter)") {
                    counter += 1
                }
                Nested()
            }
        }

        let s = Sample()
        let graph = try Graph(content: s)
        try graph.rebuildIfNeeded()
        var button: Button {
            graph.element(at: [0, 0], type: Button.self)
        }
        var nestedButton: Button {
            graph.element(at: [0, 1, 0], type: Button.self)
        }
        #expect(button.title == "0")
        #expect(nestedButton.title == "0")

        nestedButton.action()
        try graph.rebuildIfNeeded()

        #expect(button.title == "0")
        #expect(nestedButton.title == "1")

        button.action()
        try graph.rebuildIfNeeded()

        #expect(button.title == "1")
        #expect(nestedButton.title == "1")
    }

    @Test func testBindings() throws {
        struct Nested: Element {
            @UVBinding var counter: Int
            var body: some Element {
                Button("\(counter)") {
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
        var nestedButton: Button {
            graph.element(at: [0, 0], type: Button.self)
        }
        #expect(nestedButton.title == "0")

        nestedButton.action()
        try graph.rebuildIfNeeded()
        #expect(nestedButton.title == "1")
    }

    @Test func testUnusedBinding() throws {
        struct Nested: Element {
            @UVBinding var counter: Int
            var body: some Element {
                Button("") {
                    counter += 1
                }
                .debug { nestedBodyCount += 1 }
            }
        }

        struct Sample: Element {
            @UVState private var counter = 0
            var body: some Element {
                Button("\(counter)") {}
                Nested(counter: $counter)
                    .debug { sampleBodyCount += 1 }
            }
        }

        let s = Sample()
        let graph = try Graph(content: s)
        try graph.rebuildIfNeeded()
        var nestedButton: Button {
            graph.element(at: [0, 1, 0], type: Button.self)
        }
        #expect(sampleBodyCount == 1)
        #expect(nestedBodyCount == 1)

        nestedButton.action()
        try graph.rebuildIfNeeded()

        #expect(sampleBodyCount == 2)
        #expect(nestedBodyCount == 1)
    }

    // Environment Tests

    @Test func testEnvironment1() throws {
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

    @Test func testEnvironment2() throws {
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

        let s = Example1()
        let graph = try Graph(content: s)
        try graph.rebuildIfNeeded()
        #expect(graph.element(at: [0, 0], type: Example3.self).value == "Hello world")
    }
}

extension UVEnvironmentValues {
    @UVEntry
    var exampleValue: String = ""
}

extension Graph {
    func element<V>(at path: [Int], type: V.Type) -> V {
        var node: Node = root
        for index in path {
            node = node.children[index]
        }
        return node.element as! V
    }
}
