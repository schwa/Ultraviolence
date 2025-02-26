import SwiftUI
import UltraviolenceExamples

struct ContentView: View {
    @State
    private var demo: Demo?

    var body: some View {
        NavigationSplitView {
            List(selection: $demo) {
                row(for: MixedDemoView.self)
                row(for: TriangleDemoView.self)
                #if canImport(AppKit)
                row(for: OffscreenDemoView.self)
                #endif
                row(for: ComputeDemoView.self)
                row(for: BouncingTeapotsDemoView.self)
            }
        } detail: {
            if let demo {
                AnyView(demo.type.init())// .id(currentDemo)
            }
        }
    }

    @ViewBuilder
    func row(for type: any DemoView.Type) -> some View {
        let demo = Demo(type)
        NavigationLink(value: demo) {
            Label(demo.name, systemImage: "puzzlepiece")
                .truncationMode(.tail)
                .lineLimit(1)
        }
    }
}

#Preview {
    ContentView()
}

protocol DemoView: View {
    @MainActor init()
}

struct Demo: Hashable {
    var type: any DemoView.Type

    init <T>(_ type: T.Type) where T: DemoView {
        self.type = type
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        ObjectIdentifier(lhs.type) == ObjectIdentifier(rhs.type)
    }

    func hash(into hasher: inout Hasher) {
        ObjectIdentifier(type).hash(into: &hasher)
    }

    var name: String {
        String(describing: type)
            .replacingOccurrences(of: "DemoView", with: "")
            .replacing(#/[A-Z][^A-Z]+/#) { match in
                String(match.output) + " "
            }
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
