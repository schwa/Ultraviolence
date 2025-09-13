import SwiftUI
import Ultraviolence

/// Tree view showing the node hierarchy
struct NodeTreeView: View {
    let snapshot: SystemSnapshot
    @Binding var selectedNodeID: String?
    let searchText: String

    private var rootNodes: [NodeSnapshot] {
        snapshot.nodes.filter { $0.parentIdentifier == nil }
    }

    private var filteredNodes: Set<String> {
        guard !searchText.isEmpty else {
            return Set(snapshot.nodes.map(\.identifier))
        }

        // Find nodes that match the search
        let matchingNodes = snapshot.nodes.filter { node in
            node.elementType.localizedCaseInsensitiveContains(searchText) ||
                node.identifier.localizedCaseInsensitiveContains(searchText) ||
                node.stateProperties.contains { prop in
                    prop.key.localizedCaseInsensitiveContains(searchText) ||
                        prop.value.localizedCaseInsensitiveContains(searchText)
                }
        }

        // Include all ancestors of matching nodes
        var includedNodes = Set<String>()
        for node in matchingNodes {
            includedNodes.insert(node.identifier)

            // Add all ancestors
            var currentID = node.parentIdentifier
            while let parentID = currentID {
                includedNodes.insert(parentID)
                currentID = snapshot.nodes.first { $0.identifier == parentID }?.parentIdentifier
            }
        }

        return includedNodes
    }

    var body: some View {
        List(selection: $selectedNodeID) {
            ForEach(rootNodes, id: \.identifier) { node in
                if filteredNodes.contains(node.identifier) {
                    NodeRowView(
                        node: node,
                        snapshot: snapshot,
                        filteredNodes: filteredNodes,
                        selectedNodeID: $selectedNodeID
                    )
                }
            }
        }
        .listStyle(.sidebar)
    }
}

/// Individual node row in the tree
struct NodeRowView: View {
    let node: NodeSnapshot
    let snapshot: SystemSnapshot
    let filteredNodes: Set<String>
    @Binding var selectedNodeID: String?
    @State private var isExpanded = true

    private var children: [NodeSnapshot] {
        snapshot.nodes.filter { $0.parentIdentifier == node.identifier && filteredNodes.contains($0.identifier) }
    }

    private var isDirty: Bool {
        snapshot.dirtyIdentifiers.contains(node.identifier)
    }

    private var icon: String {
        if node.elementType.contains("TupleElement") {
            return "square.stack.3d.up"
        }
        if node.elementType.contains("Empty") {
            return "circle.dotted"
        }
        if !node.stateProperties.isEmpty {
            return "cube.fill"
        }
        return "cube"
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ForEach(children, id: \.identifier) { child in
                Self(
                    node: child,
                    snapshot: snapshot,
                    filteredNodes: filteredNodes,
                    selectedNodeID: $selectedNodeID
                )
            }
        } label: {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(isDirty ? .red : .secondary)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(simplifiedTypeName)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(isDirty ? .red : .primary)

                    if !node.stateProperties.isEmpty {
                        Text(statePreview)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                if isDirty {
                    Text("DIRTY")
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(.red.opacity(0.2))
                        .foregroundStyle(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                selectedNodeID = node.identifier
            }
        }
        .tag(node.identifier)
    }

    private var simplifiedTypeName: String {
        // Remove module prefixes and generic details for cleaner display
        let type = node.elementType

        // Handle TupleElement specially
        if type.contains("TupleElement<") {
            return "Tuple"
        }

        // Remove module prefix if present
        if let lastDot = type.lastIndex(of: ".") {
            return String(type[type.index(after: lastDot)...])
        }

        return type
    }

    private var statePreview: String {
        node.stateProperties
            .map { "\($0.key): \($0.value)" }
            .joined(separator: ", ")
    }
}
