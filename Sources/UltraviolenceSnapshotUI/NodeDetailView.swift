import SwiftUI
import Ultraviolence

/// Detail view showing information about a selected node
struct NodeDetailView: View {
    let node: NodeSnapshot
    let snapshot: SystemSnapshot
    let showEnvironment: Bool

    private var parent: NodeSnapshot? {
        guard let parentID = node.parentIdentifier else { return nil }
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
            VStack(alignment: .leading, spacing: 16) {
                // Header
                headerSection

                Divider()

                // Identifier
                identifierSection

                // Relationships
                if parent != nil || !children.isEmpty {
                    relationshipsSection
                }

                // State Properties
                if !node.stateProperties.isEmpty {
                    stateSection
                }

                // Environment
                if showEnvironment, !node.environmentValues.values.isEmpty || node.environmentValues.hasParent {
                    environmentSection
                }

                // Raw element description
                rawDescriptionSection
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .navigationTitle(simplifiedTypeName)
    }

    @ViewBuilder
    private var headerSection: some View {
        HStack {
            Image(systemName: "cube.fill")
                .font(.largeTitle)
                .foregroundStyle(isDirty ? .red : .blue)

            VStack(alignment: .leading, spacing: 4) {
                Text(simplifiedTypeName)
                    .font(.title2)
                    .fontWeight(.semibold)

                if isDirty {
                    Label("Dirty", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Spacer()
        }
    }

    @ViewBuilder
    private var identifierSection: some View {
        GroupBox("Identifier") {
            Text(node.identifier)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var relationshipsSection: some View {
        GroupBox("Relationships") {
            VStack(alignment: .leading, spacing: 8) {
                if let parent {
                    Label {
                        Text(simplifiedTypeName(for: parent.elementType))
                            .font(.system(.body, design: .monospaced))
                    } icon: {
                        Image(systemName: "arrow.up")
                            .foregroundStyle(.secondary)
                    }
                }

                if !children.isEmpty {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(children, id: \.identifier) { child in
                                Text(simplifiedTypeName(for: child.elementType))
                                    .font(.system(.caption, design: .monospaced))
                            }
                        }
                    } icon: {
                        Image(systemName: "arrow.down")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var stateSection: some View {
        GroupBox("State Properties") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(node.stateProperties, id: \.key) { prop in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Label(prop.key, systemImage: "square.and.pencil")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Spacer()

                            Text(prop.type)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }

                        Text(prop.value)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .clipShape(RoundedRectangle(cornerRadius: 4))

                        if !prop.dependencies.isEmpty {
                            Label {
                                Text(prop.dependencies.joined(separator: ", "))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            } icon: {
                                Image(systemName: "link")
                                    .font(.caption2)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var environmentSection: some View {
        GroupBox("Environment") {
            VStack(alignment: .leading, spacing: 8) {
                if node.environmentValues.hasParent {
                    Label("Has parent environment", systemImage: "arrow.up.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !node.environmentValues.values.isEmpty {
                    ForEach(Array(node.environmentValues.values.sorted { $0.key < $1.key }), id: \.key) { key, value in
                        HStack(alignment: .top) {
                            Text(key)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 150, alignment: .trailing)

                            Text(value)
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                } else if !node.environmentValues.hasParent {
                    Text("No environment values")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var rawDescriptionSection: some View {
        GroupBox("Element Description") {
            Text(node.elementDescription)
                .font(.system(.caption2, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var simplifiedTypeName: String {
        simplifiedTypeName(for: node.elementType)
    }

    private func simplifiedTypeName(for type: String) -> String {
        if type.contains("TupleElement<") {
            return "Tuple"
        }

        if let lastDot = type.lastIndex(of: ".") {
            return String(type[type.index(after: lastDot)...])
        }

        return type
    }
}
