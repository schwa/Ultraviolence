import QuartzCore
import SwiftUI

internal struct RenderViewDebugViewModifier <Root>: ViewModifier where Root: Element {
    @State
    var debugInspectorIsPresented = true

    @Environment(RenderView<Root>.ViewModel.self)
    var viewModel

    func body(content: Content) -> some View {
        content
            .toolbar {
                Toggle("Inspector", systemImage: "ladybug", isOn: $debugInspectorIsPresented)
            }
            .inspector(isPresented: $debugInspectorIsPresented) {
                Text("\(viewModel.graph.root)")
                List([NodeListBox(node: viewModel.graph.root)], children: \.children) { box in
                    let node = box.node
                    Text("\(node.shortDescription)").fixedSize().font(.caption2)
                }
                .inspectorColumnWidth(min: 200, ideal: 300)
            }
    }
}

internal struct NodeListBox: Identifiable {
    var id: ObjectIdentifier {
        ObjectIdentifier(node)
    }
    var node: Node
    // swiftlint:disable:next discouraged_optional_collection
    var children: [Self]? {
        node.children.map { Self(node: $0) }
    }
}
