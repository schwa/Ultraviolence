import Combine
@testable import UltraviolenceRedux
@testable import UltraviolenceSupport
import Testing

final class Model: ObservableObject {
    @Published var counter: Int = 0
}

extension RenderPass {
    func debug(_ f: () -> ()) -> some RenderPass {
        f()
        return self
    }
}

struct ContentRenderPass: RenderPass {
    @ObservedObject var model = Model()
    var body: some RenderPass {
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

    // Test that a button can self update its title
    @Test
    func simpleUpdate() {
        let v = ContentRenderPass()

        let graph = Graph(content: v)
        var button: Button {
            try! #require(graph.renderPass(at: [0], type: Button.self))
        }
        #expect(button.title == "0")
        button.action()
        graph.rebuildIfNeeded()
        #expect(button.title == "1")
    }

    // MARK: ObservedObject tests

    @Test
    func constantNested() {
        @MainActor struct Nested: RenderPass {
            var body: some RenderPass {
                nestedBodyCount += 1
                return Button("Nested Button") {}
            }
        }

        struct ContentRenderPass: RenderPass {
            @ObservedObject var model = Model()
            var body: some RenderPass {
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
        let graph = Graph(content: v)
        graph.dump()
        #expect(contentRenderPassBodyCount == 1)
        #expect(nestedBodyCount == 1)
        var button: Button {
            try! #require(graph.renderPass(at: [0, 0], type: Button.self))
        }
        button.action()
        graph.rebuildIfNeeded()
        #expect(contentRenderPassBodyCount == 2)
        #expect(nestedBodyCount == 1)
    }

    @Test
    func changedNested() {
        struct Nested: RenderPass {
            var counter: Int
            var body: some RenderPass {
                nestedBodyCount += 1
                return Button("Nested Button") {}
            }
        }

        struct ContentRenderPass: RenderPass {
            @ObservedObject var model = Model()
            var body: some RenderPass {
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
        let graph = Graph(content: v)
        #expect(contentRenderPassBodyCount == 1)
        #expect(nestedBodyCount == 1)
        var button: Button {
            try! #require(graph.renderPass(at: [0, 0], type: Button.self))
        }
        button.action()
        graph.rebuildIfNeeded()
        #expect(contentRenderPassBodyCount == 2)
        #expect(nestedBodyCount == 2)
    }

    @Test
    func unchangedNested() {
        struct Nested: RenderPass {
            var isLarge: Bool = false
            var body: some RenderPass {
                nestedBodyCount += 1
                return Button("Nested Button") {}
            }
        }

        struct ContentRenderPass: RenderPass {
            @ObservedObject var model = Model()
            var body: some RenderPass {
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
        let graph = Graph(content: v)
        #expect(contentRenderPassBodyCount == 1)
        #expect(nestedBodyCount == 1)
        var button: Button {
            try! #require(graph.renderPass(at: [0, 0], type: Button.self))
        }
        button.action()
        graph.rebuildIfNeeded()
        #expect(contentRenderPassBodyCount == 2)
        #expect(nestedBodyCount == 1)
    }

    @Test
    func unchangedNestedWithObservedObject() {
        struct Nested: RenderPass {
            @ObservedObject var model = nestedModel
            var body: some RenderPass {
                nestedBodyCount += 1
                return Button("Nested Button") {}
            }
        }

        struct ContentRenderPass: RenderPass {
            @ObservedObject var model = Model()
            var body: some RenderPass {
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
        let graph = Graph(content: v)
        #expect(contentRenderPassBodyCount == 1)
        #expect(nestedBodyCount == 1)
        var button: Button {
            try! #require(graph.renderPass(at: [0, 0], type: Button.self))
        }
        button.action()
        graph.rebuildIfNeeded()
        #expect(contentRenderPassBodyCount == 2)
        #expect(nestedBodyCount == 1)
    }

    @Test
    func binding1() {
        struct Nested: RenderPass {
            @Binding var counter: Int
            var body: some RenderPass {
                nestedBodyCount += 1
                return Button("Nested Button") {}
            }
        }

        struct ContentRenderPass: RenderPass {
            @ObservedObject var model = Model()
            var body: some RenderPass {
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
        let graph = Graph(content: v)
        #expect(contentRenderPassBodyCount == 1)
        #expect(nestedBodyCount == 1)
        var button: Button {
            try! #require(graph.renderPass(at: [0, 0], type: Button.self))
        }
        button.action()
        graph.rebuildIfNeeded()
        #expect(contentRenderPassBodyCount == 2)
        #expect(nestedBodyCount == 2)
    }

    @Test
    func binding2() {
        struct Nested: RenderPass {
            @Binding var counter: Int
            var body: some RenderPass {
                nestedBodyCount += 1
                return Button("\(counter)") { counter += 1 }
            }
        }

        struct ContentRenderPass: RenderPass {
            @ObservedObject var model = Model()
            var body: some RenderPass {
                Nested(counter: $model.counter)
                    .debug {
                        contentRenderPassBodyCount += 1
                    }
            }
        }

        let v = ContentRenderPass()
        let graph = Graph(content: v)
        var button: Button {
            try! #require(graph.renderPass(at: [0, 0], type: Button.self))
        }
        #expect(contentRenderPassBodyCount == 1)
        #expect(nestedBodyCount == 1)
        #expect(button.title == "0")
        button.action()
        graph.rebuildIfNeeded()
        #expect(contentRenderPassBodyCount == 2)
        #expect(nestedBodyCount == 2)
        #expect(button.title == "1")
    }

    // MARK: State tests

    @Test
    func simpleState() {
        struct Nested: RenderPass {
            @State private var counter = 0
            var body: some RenderPass {
                Button("\(counter)") {
                    counter += 1
                }
            }
        }

        struct Sample: RenderPass {
            @State private var counter = 0
            var body: some RenderPass {
                Button("\(counter)") {
                    counter += 1
                }
                Nested()
            }
        }

        let s = Sample()
        let graph = Graph(content: s)
        var button: Button {
            try! #require(graph.renderPass(at: [0, 0], type: Button.self))
        }
        var nestedButton: Button {
            try! #require(graph.renderPass(at: [0, 1, 0], type: Button.self))
        }
        #expect(button.title == "0")
        #expect(nestedButton.title == "0")

        nestedButton.action()
        graph.rebuildIfNeeded()

        #expect(button.title == "0")
        #expect(nestedButton.title == "1")

        button.action()
        graph.rebuildIfNeeded()

        #expect(button.title == "1")
        #expect(nestedButton.title == "1")
    }

    @Test
    func statePlusBindings() {
        struct Nested: RenderPass {
            @Binding var counter: Int
            var body: some RenderPass {
                Button("\(counter)") {
                    counter += 1
                }
            }
        }

        struct Sample: RenderPass {
            @State private var counter = 0
            var body: some RenderPass {
                Nested(counter: $counter)
            }
        }

        let s = Sample()
        let graph = Graph(content: s)
        var nestedButton: Button {
            try! #require(graph.renderPass(at: [0, 0], type: Button.self))
        }
        #expect(nestedButton.title == "0")

        nestedButton.action()
        graph.rebuildIfNeeded()
        #expect(nestedButton.title == "1")
    }

    @Test
    func unusedBinding() {
        struct Nested: RenderPass {
            @Binding var counter: Int
            var body: some RenderPass {
                Button("") {
                    counter += 1
                }
                .debug { nestedBodyCount += 1 }
            }
        }

        struct Sample: RenderPass {
            @State private var counter = 0
            var body: some RenderPass {
                Button("\(counter)") {}
                Nested(counter: $counter)
                    .debug { sampleBodyCount += 1 }
            }
        }

        let s = Sample()
        let graph = Graph(content: s)
        var nestedButton: Button {
            try! #require(graph.renderPass(at: [0, 1, 0], type: Button.self))
        }
        #expect(sampleBodyCount == 1)
        #expect(nestedBodyCount == 1)

        nestedButton.action()
        graph.rebuildIfNeeded()

        #expect(sampleBodyCount == 2)
        #expect(nestedBodyCount == 1)
    }

    // MARK: Environment Tests

    @Test
    func environment1() throws {
        struct Example1: RenderPass {
            var body: some RenderPass {
                EnvironmentReader(keyPath: \.exampleValue) { Example2(value: $0) }
                    .environment(\.exampleValue, "Hello world")
            }
        }

        struct Example2: RenderPass, BodylessRenderPass {
            typealias Body = Never
            var value: String
            func _expandNode(_ node: Node) {
            }
        }

        let s = Example1()
        let graph = Graph(content: s)
        try #expect(#require(graph.renderPass(at: [0], type: Example2.self)).value == "Hello world")
    }

    @Test
    func environment2() throws {
        struct Example1: RenderPass {
            var body: some RenderPass {
                Example2()
                    .environment(\.exampleValue, "Hello world")
            }
        }

        struct Example2: RenderPass {
            @Environment(\.exampleValue)
            var value
            var body: some RenderPass {
                Example3(value: value)
            }
        }

        struct Example3: RenderPass, BodylessRenderPass {
            typealias Body = Never
            var value: String
            func _expandNode(_ node: Node) {
            }
        }

        let s = Example1()
        let graph = Graph(content: s)
        try #expect(#require(graph.renderPass(at: [0, 0], type: Example3.self)).value == "Hello world")
    }

    // MARK: Optional tests

    @Test func optionalNil() {
        let flag = false
        let stack = Stack {
            if flag {
                Button("Button") {}
            }
        }
        let graph = Graph(content: stack)
        #expect(graph.renderPass(at: [0], type: Button.self) == nil)
    }

    @Test func optionalSome() {
        let flag = true
        let stack = Stack {
            if flag {
                Button("Button") {}
            }
        }
        let graph = Graph(content: stack)
        #expect(try! #require(graph.renderPass(at: [0], type: Button.self)).title == "Button")
    }
}

// MARK: -

extension EnvironmentValues {
    @Entry
    var exampleValue: String = ""
}

extension Graph {
    func renderPass(at path: [Int]) -> (any RenderPass)? {
        var node: Node = root
        for index in path {
            node = node.children[index]
        }
        return node.renderPass
    }

    func renderPass<V>(at path: [Int], type: V.Type) -> V? {
        var node: Node = root
        for index in path {
            node = node.children[index]
        }
        return node.renderPass as? V
    }
}

struct Stack <Content>: RenderPass where Content: RenderPass {
    var content: Content

    init(@RenderPassBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some RenderPass {
        content
    }
}
