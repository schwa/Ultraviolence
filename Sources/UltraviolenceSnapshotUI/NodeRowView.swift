import SwiftUI
import Ultraviolence

struct NodeRowView: View {
    let node: NodeSnapshot
    let snapshot: SystemSnapshot
    @Binding var selectedNodeID: String?
    
    private var parsedType: ParsedTypeName {
        ParsedTypeName(node.elementType)
    }

    private var isDirty: Bool {
        snapshot.dirtyIdentifiers.contains(node.identifier)
    }

    private var icon: String {
        if parsedType.typeName == "TupleElement" {
            return "square.stack.3d.up"
        }
        if parsedType.typeName.contains("Empty") {
            return "circle.dotted"
        }
        if !node.stateProperties.isEmpty {
            return "cube.fill"
        }
        return "cube"
    }

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(isDirty ? .red : .secondary)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 1) {
                Text(parsedType.typeName)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(isDirty ? .red : .primary)

                if !node.stateProperties.isEmpty {
                    Text(statePreview)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            HStack {
                if isDirty {
                    Text("DIRTY")
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(.red.opacity(0.2))
                        .foregroundStyle(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                
                if node.needsSetup {
                    Text("SETUP")
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(.orange.opacity(0.2))
                        .foregroundStyle(.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedNodeID = node.identifier
        }
        .accessibilityAddTraits(.isButton)
        .tag(node.identifier)
    }

    private var statePreview: String {
        node.stateProperties
            .map { "\($0.key): \($0.value)" }
            .joined(separator: ", ")
    }
}
