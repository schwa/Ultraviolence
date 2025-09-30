import SwiftUI
import Ultraviolence

internal struct ExpandableSection: View {
    let content: String
    @State private var showPopover = false

    var needsExpansion: Bool {
        content.contains("\n") || content.count > 80
    }

    var body: some View {
        HStack {
            Text(content)
                .monospaced()
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            if needsExpansion {
                Button("More") {
                    showPopover = true
                }
                .popover(isPresented: $showPopover) {
                    ScrollView {
                        Text(content)
                            .monospaced()
                            .textSelection(.enabled)
                            .padding()
                    }
                    .frame(width: 1_200, height: 800)
                }
            }
        }
    }
}

/// Detail view showing information about a selected node
internal struct NodeDetailView: View {
    let node: NodeSnapshot
    let snapshot: SystemSnapshot

    private var parent: NodeSnapshot? {
        guard let parentID = node.parentIdentifier else {
            return nil
        }
        return snapshot.nodes.first { $0.identifier == parentID }
    }

    private var children: [NodeSnapshot] {
        snapshot.nodes.filter { $0.parentIdentifier == node.identifier }
    }

    private var isDirty: Bool {
        snapshot.dirtyIdentifiers.contains(node.identifier)
    }

    var body: some View {
        ScrollView {
            Form {
                LabeledContent("Type") {
                    Text(ParsedTypeName(node.elementType).typeName)
                }

                LabeledContent("Full Type") {
                    Text(ParsedTypeName(node.elementType).fullName)
                }

                LabeledContent("Identifier") {
                    Text(node.identifier)
                        .textSelection(.enabled)
                }

                LabeledContent("Status") {
                    HStack {
                        if isDirty {
                            Text("Dirty")
                        }
                        if node.needsSetup {
                            Text("Needs Setup")
                        }
                    }
                }

                LabeledContent("Parent") {
                    Text(parent != nil ? "Yes" : "No")
                }

                LabeledContent("Children") {
                    Text("\(children.count)")
                }

                stateSection

                environmentSection

                rawDescriptionSection
            }
            .padding()
        }
        .navigationTitle(ParsedTypeName(node.elementType).typeName)
    }

    @ViewBuilder
    private var stateSection: some View {
        LabeledContent("State") {
            VStack {
                ForEach(node.stateProperties, id: \.key) { prop in
                    Text(prop.key)
                    ExpandableSection(content: prop.value)
                }
            }
        }
    }

    @ViewBuilder
    private var environmentSection: some View {
        LabeledContent("Environment") {
            VStack {
                ForEach(Array(node.environmentValues.values.sorted { $0.key < $1.key }), id: \.key) { key, value in
                    HStack(alignment: .firstTextBaseline) {
                        Text(key)
                        ExpandableSection(content: value)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var rawDescriptionSection: some View {
        LabeledContent("Description") {
            ExpandableSection(content: node.elementDescription)
        }
    }
}
