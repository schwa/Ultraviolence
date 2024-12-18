import Combine
@testable import NotSwiftUI
import Testing

final class Model: ObservableObject {
    @Published var counter: Int = 0
}

extension View {
    func debug(_ f: () -> ()) -> some View {
        f()
        return self
    }
}

struct ContentView: View {
    @ObservedObject var model = Model()
    var body: some View {
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
var contentViewBodyCount = 0

@MainActor
var sampleBodyCount = 0

@Suite(.serialized)
@MainActor
struct NotSwiftUIStateTests {
    init() {
        nestedBodyCount = 0
        contentViewBodyCount = 0
        nestedModel.counter = 0
        sampleBodyCount = 0
    }

    // Test that a button can self update its title
    @Test
    func simpleUpdate() {
        let v = ContentView()

        let graph = Graph(content: v)
        var button: Button {
            try! #require(graph.view(at: [0], type: Button.self))
        }
        #expect(button.title == "0")
        button.action()
        graph.rebuildIfNeeded()
        #expect(button.title == "1")
    }

    // MARK: ObservedObject tests

    @Test
    func constantNested() {
        @MainActor struct Nested: View {
            var body: some View {
                nestedBodyCount += 1
                return Button("Nested Button") {}
            }
        }

        struct ContentView: View {
            @ObservedObject var model = Model()
            var body: some View {
                Button("\(model.counter)") {
                    model.counter += 1
                }
                Nested()
                    .debug {
                        contentViewBodyCount += 1
                    }
            }
        }

        let v = ContentView()
        let graph = Graph(content: v)
        graph.dump()
        #expect(contentViewBodyCount == 1)
        #expect(nestedBodyCount == 1)
        var button: Button {
            try! #require(graph.view(at: [0, 0], type: Button.self))
        }
        button.action()
        graph.rebuildIfNeeded()
        #expect(contentViewBodyCount == 2)
        #expect(nestedBodyCount == 1)
    }

    @Test
    func changedNested() {
        struct Nested: View {
            var counter: Int
            var body: some View {
                nestedBodyCount += 1
                return Button("Nested Button") {}
            }
        }

        struct ContentView: View {
            @ObservedObject var model = Model()
            var body: some View {
                Button("\(model.counter)") {
                    model.counter += 1
                }
                Nested(counter: model.counter)
                    .debug {
                        contentViewBodyCount += 1
                    }
            }
        }

        let v = ContentView()
        let graph = Graph(content: v)
        #expect(contentViewBodyCount == 1)
        #expect(nestedBodyCount == 1)
        var button: Button {
            try! #require(graph.view(at: [0, 0], type: Button.self))
        }
        button.action()
        graph.rebuildIfNeeded()
        #expect(contentViewBodyCount == 2)
        #expect(nestedBodyCount == 2)
    }

    @Test
    func unchangedNested() {
        struct Nested: View {
            var isLarge: Bool = false
            var body: some View {
                nestedBodyCount += 1
                return Button("Nested Button") {}
            }
        }

        struct ContentView: View {
            @ObservedObject var model = Model()
            var body: some View {
                Button("\(model.counter)") {
                    model.counter += 1
                }
                Nested(isLarge: model.counter > 10)
                    .debug {
                        contentViewBodyCount += 1
                    }
            }
        }

        let v = ContentView()
        let graph = Graph(content: v)
        #expect(contentViewBodyCount == 1)
        #expect(nestedBodyCount == 1)
        var button: Button {
            try! #require(graph.view(at: [0, 0], type: Button.self))
        }
        button.action()
        graph.rebuildIfNeeded()
        #expect(contentViewBodyCount == 2)
        #expect(nestedBodyCount == 1)
    }

    @Test
    func unchangedNestedWithObservedObject() {
        struct Nested: View {
            @ObservedObject var model = nestedModel
            var body: some View {
                nestedBodyCount += 1
                return Button("Nested Button") {}
            }
        }

        struct ContentView: View {
            @ObservedObject var model = Model()
            var body: some View {
                Button("\(model.counter)") {
                    model.counter += 1
                }
                Nested()
                    .debug {
                        contentViewBodyCount += 1
                    }
            }
        }

        let v = ContentView()
        let graph = Graph(content: v)
        #expect(contentViewBodyCount == 1)
        #expect(nestedBodyCount == 1)
        var button: Button {
            try! #require(graph.view(at: [0, 0], type: Button.self))
        }
        button.action()
        graph.rebuildIfNeeded()
        #expect(contentViewBodyCount == 2)
        #expect(nestedBodyCount == 1)
    }

    @Test
    func binding1() {
        struct Nested: View {
            @Binding var counter: Int
            var body: some View {
                nestedBodyCount += 1
                return Button("Nested Button") {}
            }
        }

        struct ContentView: View {
            @ObservedObject var model = Model()
            var body: some View {
                Button("\(model.counter)") {
                    model.counter += 1
                }
                Nested(counter: $model.counter)
                    .debug {
                        contentViewBodyCount += 1
                    }
            }
        }

        let v = ContentView()
        let graph = Graph(content: v)
        #expect(contentViewBodyCount == 1)
        #expect(nestedBodyCount == 1)
        var button: Button {
            try! #require(graph.view(at: [0, 0], type: Button.self))
        }
        button.action()
        graph.rebuildIfNeeded()
        #expect(contentViewBodyCount == 2)
        #expect(nestedBodyCount == 2)
    }

    @Test
    func binding2() {
        struct Nested: View {
            @Binding var counter: Int
            var body: some View {
                nestedBodyCount += 1
                return Button("\(counter)") { counter += 1 }
            }
        }

        struct ContentView: View {
            @ObservedObject var model = Model()
            var body: some View {
                Nested(counter: $model.counter)
                    .debug {
                        contentViewBodyCount += 1
                    }
            }
        }

        let v = ContentView()
        let graph = Graph(content: v)
        var button: Button {
            try! #require(graph.view(at: [0, 0], type: Button.self))
        }
        #expect(contentViewBodyCount == 1)
        #expect(nestedBodyCount == 1)
        #expect(button.title == "0")
        button.action()
        graph.rebuildIfNeeded()
        #expect(contentViewBodyCount == 2)
        #expect(nestedBodyCount == 2)
        #expect(button.title == "1")
    }

    // MARK: State tests

    @Test
    func simpleState() {
        struct Nested: View {
            @State private var counter = 0
            var body: some View {
                Button("\(counter)") {
                    counter += 1
                }
            }
        }

        struct Sample: View {
            @State private var counter = 0
            var body: some View {
                Button("\(counter)") {
                    counter += 1
                }
                Nested()
            }
        }

        let s = Sample()
        let graph = Graph(content: s)
        var button: Button {
            try! #require(graph.view(at: [0, 0], type: Button.self))
        }
        var nestedButton: Button {
            try! #require(graph.view(at: [0, 1, 0], type: Button.self))
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
        struct Nested: View {
            @Binding var counter: Int
            var body: some View {
                Button("\(counter)") {
                    counter += 1
                }
            }
        }

        struct Sample: View {
            @State private var counter = 0
            var body: some View {
                Nested(counter: $counter)
            }
        }

        let s = Sample()
        let graph = Graph(content: s)
        var nestedButton: Button {
            try! #require(graph.view(at: [0, 0], type: Button.self))
        }
        #expect(nestedButton.title == "0")

        nestedButton.action()
        graph.rebuildIfNeeded()
        #expect(nestedButton.title == "1")
    }

    @Test
    func unusedBinding() {
        struct Nested: View {
            @Binding var counter: Int
            var body: some View {
                Button("") {
                    counter += 1
                }
                .debug { nestedBodyCount += 1 }
            }
        }

        struct Sample: View {
            @State private var counter = 0
            var body: some View {
                Button("\(counter)") {}
                Nested(counter: $counter)
                    .debug { sampleBodyCount += 1 }
            }
        }

        let s = Sample()
        let graph = Graph(content: s)
        var nestedButton: Button {
            try! #require(graph.view(at: [0, 1, 0], type: Button.self))
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
        struct Example1: View {
            var body: some View {
                EnvironmentReader(keyPath: \.exampleValue) { Example2(value: $0) }
                    .environment(\.exampleValue, "Hello world")
            }
        }

        struct Example2: View, BodylessView {
            typealias Body = Never
            var value: String
            func _expandNode(_ node: Node) {
            }
        }

        let s = Example1()
        let graph = Graph(content: s)
        try #expect(#require(graph.view(at: [0], type: Example2.self)).value == "Hello world")
    }

    @Test
    func environment2() throws {
        struct Example1: View {
            var body: some View {
                Example2()
                    .environment(\.exampleValue, "Hello world")
            }
        }

        struct Example2: View {
            @Environment(\.exampleValue)
            var value
            var body: some View {
                Example3(value: value)
            }
        }

        struct Example3: View, BodylessView {
            typealias Body = Never
            var value: String
            func _expandNode(_ node: Node) {
            }
        }

        let s = Example1()
        let graph = Graph(content: s)
        try #expect(#require(graph.view(at: [0, 0], type: Example3.self)).value == "Hello world")
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
        #expect(graph.view(at: [0], type: Button.self) == nil)
    }

    @Test func optionalSome() {
        let flag = true
        let stack = Stack {
            if flag {
                Button("Button") {}
            }
        }
        let graph = Graph(content: stack)
        #expect(try! #require(graph.view(at: [0], type: Button.self)).title == "Button")
    }
}

// MARK: -

extension EnvironmentValues {
    @Entry
    var exampleValue: String = ""
}

extension Graph {
    func view(at path: [Int]) -> (any View)? {
        var node: Node = root
        for index in path {
            node = node.children[index]
        }
        return node.view
    }

    func view<V>(at path: [Int], type: V.Type) -> V? {
        var node: Node = root
        for index in path {
            node = node.children[index]
        }
        return node.view as? V
    }
}

struct Stack <Content>: View where Content: View {
    var content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
    }
}
