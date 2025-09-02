import SwiftUI
import UltraviolenceExamples

struct ContentView: View {
    @State
    private var page: Page?

    private var splatsOnly = false

    var body: some View {
        NavigationSplitView {
            List(selection: $page) {
#if os(iOS) || (os(iOS) || (os(macOS) && !arch(x86_64)))
                row(for: GaussianSplatDemoView.self)
#endif // os(iOS) || (os(macOS) && !arch(x86_64))
                if !splatsOnly {
                    row(for: BlinnPhongDemoView.self)
                    row(for: GridShaderDemoView.self)
                    row(for: SkyboxDemoView.self)
                    row(for: MixedDemoView.self)
                    row(for: TriangleDemoView.self)
#if canImport(AppKit)
                    row(for: OffscreenDemoView.self)
#endif
                    row(for: ComputeDemoView.self)
                    row(for: BouncingTeapotsDemoView.self)
                    row(for: StencilDemoView.self)
                    row(for: LUTDemoView.self)
#if canImport(MetalFX)
                    row(for: MetalFXDemoView.self)
#endif
                }
            }
        } detail: {
            if let page {
                page.content().navigationTitle(page.name)
            }
        }
    }

    func row(for page: Page) -> some View {
        NavigationLink(value: page) {
            VStack(alignment: .leading) {
                HStack {
                    Label(page.id, systemImage: "puzzlepiece")
                        .truncationMode(.tail)
                        .lineLimit(1)
                        .fixedSize()
                    ForEach(page.keywords, id: \.self) { keyword in
                        Text(keyword)
                            .fixedSize()
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding([.leading, .trailing], 4)
                            .padding([.top, .bottom], 2)
                            .background(Color.green, in: Capsule())

                    }
                }
                if let description = page.description {
                    Text(description)
                    .lineLimit(nil)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

            }
        }
    }

    func row(for demo: any DemoView.Type) -> some View {
        let page = Page(id: demo.name, keywords: demo.keywords, description: demo.demoDescription) { AnyView(demo.init()) }
        return row(for: page)
    }
}

#Preview {
    ContentView()
}

struct Page: Hashable {
    let id: String
    var name: String {
        id
    }
    let keywords: [String]
    let description: String?
    let content: () -> AnyView

    init(id: String, keywords: [String], description: String?, content: @escaping () -> AnyView) {
        self.id = id
        self.keywords = keywords
        self.description = description
        self.content = content
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
