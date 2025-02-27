import QuartzCore
import SwiftUI

internal struct RenderViewDebugViewModifier <Root>: ViewModifier where Root: Element {
    @State
    var debugInspectorIsPresented = false

    @Environment(RenderView<Root>.ViewModel.self)
    var viewModel

    @State
    var refreshCount = 0

    @State
    var selection: NodeListBox?

    func body(content: Content) -> some View {
        content
            .toolbar {
                Toggle("Inspector", systemImage: "ladybug", isOn: $debugInspectorIsPresented)
                Button("Refresh", systemImage: "arrow.trianglehead.clockwise") {
                    refreshCount += 1
                }
            }
            .inspector(isPresented: $debugInspectorIsPresented) {
                VStack {
                    List([NodeListBox(node: viewModel.graph.root)], children: \.children, selection: $selection) { box in
                        let node = box.node

                        Label(node.debugName, systemImage: "cube").font(.caption2).tag(box)
                    }
                    if let node = selection?.node {
                        ScrollView {
                            Form {
                                LabeledContent("ID", value: "\(ObjectIdentifier(node))")
                                LabeledContent("Name", value: "\(node.debugName)")
                                LabeledContent("Debug Label", value: "\(node.debugLabel ?? "")")
                                LabeledContent("Children", value: "\(node.children.count)")
                                LabeledContent("# State", value: "\(node.stateProperties.count)")
                                LabeledContent("Element", value: "\(node.element)")
                                //                            LabeledContent("# Environment", value: "\(node.environmentValues.count)")
                            }
                        }
                        .font(.caption2)
                    }
                }
                .id(refreshCount)
                .inspectorColumnWidth(min: 200, ideal: 300)
            }
            .onChange(of: debugInspectorIsPresented) {
                refreshCount += 1
            }
    }
}

internal struct NodeListBox: Identifiable, Hashable {
    var id: ObjectIdentifier {
        ObjectIdentifier(node)
    }
    var node: Node
    // swiftlint:disable:next discouraged_optional_collection
    var children: [Self]? {
        node.children.isEmpty ? nil : node.children.map { Self(node: $0) }
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
