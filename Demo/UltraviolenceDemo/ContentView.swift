import SwiftUI
import UltraviolenceExamples

protocol DemoView: View {
    @MainActor init()
}

struct ContentView: View {
    @State
    private var page: Page?

    var body: some View {
        NavigationSplitView {
            List(selection: $page) {
                row(for: MixedDemoView.self)
                row(for: TriangleDemoView.self)
                #if canImport(AppKit)
                row(for: OffscreenDemoView.self)
                #endif
                row(for: ComputeDemoView.self)
                row(for: BouncingTeapotsDemoView.self)
                row(for: StencilDemoView.self)
                row(for: LUTDemoView.self)
            }
        } detail: {
            if let page {
                page.content()
            }
        }
    }

    func row(for page: Page) -> some View {
        NavigationLink(value: page) {
            Label(page.id, systemImage: "puzzlepiece")
                .truncationMode(.tail)
                .lineLimit(1)
        }
    }

    func row(for demo: any DemoView.Type) -> some View {
        let name = "\(type(of: demo))"
        let page = Page(id: name) { AnyView(demo.init()) }
        return row(for: page)
    }
}

#Preview {
    ContentView()
}

struct Page: Hashable {
    let id: String
    let content: () -> AnyView

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
