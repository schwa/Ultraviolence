import SwiftUI
import Ultraviolence

/// Main debug view that displays a system snapshot
public struct SnapshotDebugView: View {
    let snapshot: SystemSnapshot
    @State private var selectedNodeID: String?
    @State private var showEnvironment = false
    @State private var searchText = ""

    public init(snapshot: SystemSnapshot) {
        self.snapshot = snapshot
    }

    public var body: some View {
        NavigationSplitView {
            NodeTreeView(
                snapshot: snapshot,
                selectedNodeID: $selectedNodeID,
                searchText: searchText
            )
            .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 400)
            .navigationTitle("Nodes")
            .searchable(text: $searchText, prompt: "Search nodes...")
        } detail: {
            if let selectedNode = snapshot.nodes.first(where: { $0.identifier == selectedNodeID }) {
                NodeDetailView(
                    node: selectedNode,
                    snapshot: snapshot,
                    showEnvironment: showEnvironment
                )
                .toolbar {
                    ToolbarItem {
                        Toggle(isOn: $showEnvironment) {
                            Label("Environment", systemImage: "globe")
                        }
                        .toggleStyle(.button)
                    }
                }
            } else {
                ContentUnavailableView(
                    "Select a Node",
                    systemImage: "cube",
                    description: Text("Select a node from the sidebar to view details")
                )
            }
        }
        .navigationTitle("System Snapshot")
        .navigationSubtitle("\(snapshot.nodes.count) nodes • \(snapshot.dirtyIdentifiers.count) dirty")
    }
}

#Preview {
    SnapshotDebugView(snapshot: SystemSnapshot(system: System()))
}
