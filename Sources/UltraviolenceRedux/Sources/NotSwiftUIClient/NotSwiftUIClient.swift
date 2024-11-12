import NotSwiftUI

extension EnvironmentValues {
    @Entry
    var name: String?
}

@main
struct NotSwiftUIClient {
    static func main() throws {
        let root = Stack {
            Button("I am button #1") {}
            Button("I am button #2") {}
        }

        let graph = Graph(content: root)

        graph.dump()
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
