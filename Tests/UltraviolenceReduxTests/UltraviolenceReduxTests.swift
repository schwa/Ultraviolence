import Combine
@testable import UltraviolenceRedux
import UltraviolenceSupport
import Testing

struct Button: RenderPass, BuiltinRenderPass {
    typealias Body = Never

    var title: String
    var action: () -> ()

    init(_ title: String, action: @escaping () -> ()) {
        self.title = title
        self.action = action
    }

    func _buildNodeTree(_ parent: Node) {
        // todo create a UIButton
    }
}

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

    @Test func testUpdate() {
        let v = ContentRenderPass()

        let graph = Graph(content: v)
        var button: Button {
            graph.renderPass(at: [0], type: Button.self)
        }
        #expect(button.title == "0")
        button.action()
        graph.rebuildIfNeeded()
        #expect(button.title == "1")
    }

    // MARK: ObservedObject tests

    @Test func testConstantNested() {
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
        #expect(contentRenderPassBodyCount == 1)
        #expect(nestedBodyCount == 1)
        var button: Button {
            graph.renderPass(at: [0, 0], type: Button.self)
        }
        button.action()
        graph.rebuildIfNeeded()
        #expect(contentRenderPassBodyCount == 2)
        #expect(nestedBodyCount == 1)
    }

    @Test func testChangedNested() {
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
            graph.renderPass(at: [0, 0], type: Button.self)
        }
        button.action()
        graph.rebuildIfNeeded()
        #expect(contentRenderPassBodyCount == 2)
        #expect(nestedBodyCount == 2)
    }

    @Test func testUnchangedNested() {
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
            graph.renderPass(at: [0, 0], type: Button.self)
        }
        button.action()
        graph.rebuildIfNeeded()
        #expect(contentRenderPassBodyCount == 2)
        #expect(nestedBodyCount == 1)
    }

    @Test func testUnchangedNestedWithObservedObject() {
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
            graph.renderPass(at: [0, 0], type: Button.self)
        }
        button.action()
        graph.rebuildIfNeeded()
        #expect(contentRenderPassBodyCount == 2)
        #expect(nestedBodyCount == 1)
    }

    @Test func testBinding1() {
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
            graph.renderPass(at: [0, 0], type: Button.self)
        }
        button.action()
        graph.rebuildIfNeeded()
        #expect(contentRenderPassBodyCount == 2)
        #expect(nestedBodyCount == 2)
    }

    @Test func testBinding2() {
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
            graph.renderPass(at: [0, 0], type: Button.self)
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

    @Test func testSimple() {
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
            graph.renderPass(at: [0, 0], type: Button.self)
        }
        var nestedButton: Button {
            graph.renderPass(at: [0, 1, 0], type: Button.self)
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

    @Test func testBindings() {
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
            graph.renderPass(at: [0, 0], type: Button.self)
        }
        #expect(nestedButton.title == "0")

        nestedButton.action()
        graph.rebuildIfNeeded()
        #expect(nestedButton.title == "1")
    }

    @Test func testUnusedBinding() {
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
            graph.renderPass(at: [0, 1, 0], type: Button.self)
        }
        #expect(sampleBodyCount == 1)
        #expect(nestedBodyCount == 1)

        nestedButton.action()
        graph.rebuildIfNeeded()

        #expect(sampleBodyCount == 2)
        #expect(nestedBodyCount == 1)
    }

    // Environment Tests

    @Test func testEnvironment1() {
        struct Example1: RenderPass {
            var body: some RenderPass {
                EnvironmentReader(keyPath: \.exampleValue) { Example2(value: $0) }
                    .environment(\.exampleValue, "Hello world")
            }
        }

        struct Example2: RenderPass, BuiltinRenderPass {
            typealias Body = Never
            var value: String
            func _buildNodeTree(_ parent: Node) {
            }
        }

        let s = Example1()
        let graph = Graph(content: s)
        #expect(graph.renderPass(at: [0], type: Example2.self).value == "Hello world")
    }

    @Test func testEnvironment2() {
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

        struct Example3: RenderPass, BuiltinRenderPass {
            typealias Body = Never
            var value: String
            func _buildNodeTree(_ parent: Node) {
            }
        }

        let s = Example1()
        let graph = Graph(content: s)
        #expect(graph.renderPass(at: [0, 0], type: Example3.self).value == "Hello world")
    }
}

extension EnvironmentValues {
    @Entry
    var exampleValue: String = ""
}

extension Graph {
    func renderPass(at path: [Int]) -> (any BuiltinRenderPass)? {
        var node: Node = root
        for index in path {
            node = node.children[index]
        }
        return node.renderPass
    }

    func renderPass<V>(at path: [Int], type: V.Type) -> V {
        var node: Node = root
        for index in path {
            node = node.children[index]
        }
        return node.renderPass as! V
    }
}
