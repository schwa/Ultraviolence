import SwiftUI
import Ultraviolence

/// List view showing the node hierarchy
internal struct NodeListView: View {
    let snapshot: SystemSnapshot
    @Binding var selectedNodeID: String?
    let searchText: String

    struct Row: Identifiable {
        let node: NodeSnapshot
        let snapshot: SystemSnapshot
        let filteredNodes: Set<String>

        var id: String {
            node.identifier
        }

        // swiftlint:disable:next discouraged_optional_collection
        var children: [Self]? {
            let childNodes = snapshot.nodes.filter { node in
                node.parentIdentifier == node.identifier && filteredNodes.contains(node.identifier)
            }

            guard !childNodes.isEmpty else {
                return nil
            }

            return childNodes.map { childNode in
                Self(node: childNode, snapshot: snapshot, filteredNodes: filteredNodes)
            }
        }
    }

    private var rootRows: [Row] {
        let rootNodes = snapshot.nodes.filter { $0.parentIdentifier == nil }
        return rootNodes
            .filter { filteredNodes.contains($0.identifier) }
            .map { Row(node: $0, snapshot: snapshot, filteredNodes: filteredNodes) }
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
        List(rootRows, children: \.children, selection: $selectedNodeID) { row in
            NodeRowView(
                node: row.node,
                snapshot: row.snapshot,
                selectedNodeID: $selectedNodeID
            )
        }
        .controlSize(.small)
        .listStyle(.sidebar)
        .frame(minWidth: 320, idealWidth: 400)
    }
}
