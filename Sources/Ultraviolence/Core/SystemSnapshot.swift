import Foundation

/// A complete snapshot of the System state for debugging purposes
public struct SystemSnapshot: Codable, Sendable {
    public let timestamp: Date
    public let nodes: [NodeSnapshot]
    public let orderedIdentifiers: [String]
    public let dirtyIdentifiers: Set<String>
    public let activeNodeStackDepth: Int

    public init(system: System) {
        self.timestamp = Date()
        
        // Extract ordered identifiers from traversal events (only enter events to avoid duplicates)
        var extractedIdentifiers: [StructuralIdentifier] = []
        for event in system.traversalEvents {
            if case .enter(let node) = event {
                extractedIdentifiers.append(node.id)
            }
        }
        
        self.orderedIdentifiers = extractedIdentifiers.map(\.description)
        self.dirtyIdentifiers = Set(system.dirtyIdentifiers.map(\.description))
        self.activeNodeStackDepth = system.activeNodeStack.count

        // Create node snapshots
        self.nodes = extractedIdentifiers.compactMap { identifier in
            guard let node = system.nodes[identifier] else { return nil }
            return NodeSnapshot(node: node)
        }
    }
}

/// Snapshot of a single node
public struct NodeSnapshot: Codable, Sendable {
    public let identifier: String
    public let parentIdentifier: String?
    public let elementType: String
    public let elementDescription: String
    public let stateProperties: [StatePropertySnapshot]
    public let environmentValues: EnvironmentSnapshot
    public let needsSetup: Bool

    init(node: Node) {
        self.identifier = node.id.description
        self.parentIdentifier = node.parentIdentifier?.description
        self.needsSetup = node.needsSetup

        // Get element type information
        let element = node.element
        self.elementType = String(describing: type(of: element))

        // Use Mirror to get element description
        let mirror = Mirror(reflecting: element)
        var elementInfo = [String: String]()
        for child in mirror.children {
            if let label = child.label {
                elementInfo[label] = "\(child.value)"
            }
        }
        self.elementDescription = elementInfo.isEmpty ? elementType : "\(elementType)(\(elementInfo.map { "\($0.key): \($0.value)" }.joined(separator: ", ")))"

        // Extract state properties
        self.stateProperties = node.stateProperties.compactMap { key, value in
            StatePropertySnapshot(key: key, value: value)
        }

        // Capture environment
        self.environmentValues = EnvironmentSnapshot(environmentValues: node.environmentValues)
    }
}

/// Snapshot of a state property
public struct StatePropertySnapshot: Codable, Sendable {
    public let key: String
    public let type: String
    public let value: String
    public let dependencies: [String]

    init(key: String, value: Any) {
        self.key = key

        // Try to get the actual value from StateBox
        let mirror = Mirror(reflecting: value)

        // Check if this is a StateBox by looking for its structure
        if String(describing: Swift.type(of: value)).contains("StateBox") {
            self.type = "StateBox"

            // Try to access the wrapped value through the snapshotValue property
            if let valueProvider = value as? (any SnapshotValueProviding) {
                self.value = "\(valueProvider.snapshotValue)"
            } else {
                // Fallback to Mirror extraction
                if let valueChild = mirror.children.first(where: { $0.label == "_value" }) {
                    self.value = "\(valueChild.value)"
                } else {
                    self.value = "\(value)"
                }
            }

            // Extract dependencies if available
            if let depsChild = mirror.children.first(where: { $0.label == "dependencies" }) {
                // Dependencies are WeakBox<Node> array
                let depsMirror = Mirror(reflecting: depsChild.value)
                var deps = [String]()
                for child in depsMirror.children {
                    // Try to extract node identifier from WeakBox
                    let weakBoxMirror = Mirror(reflecting: child.value)
                    if let nodeChild = weakBoxMirror.children.first {
                        if let node = nodeChild.value as? Node {
                            deps.append(node.id.description)
                        }
                    }
                }
                self.dependencies = deps
            } else {
                self.dependencies = []
            }
        } else {
            // Not a StateBox
            self.type = String(describing: Swift.type(of: value))
            self.value = "\(value)"
            self.dependencies = []
        }
    }
}

/// Snapshot of environment values
public struct EnvironmentSnapshot: Codable, Sendable {
    public let values: [String: String]
    public let hasParent: Bool

    init(environmentValues: UVEnvironmentValues) {
        // Use Mirror to extract storage
        let mirror = Mirror(reflecting: environmentValues)

        if let storageChild = mirror.children.first(where: { $0.label == "storage" }),
           let storage = storageChild.value as? UVEnvironmentValues.Storage {
            // Extract values from storage
            let storageMirror = Mirror(reflecting: storage)

            // Find the values dictionary
            if let valuesChild = storageMirror.children.first(where: { $0.label == "values" }) {
                var extractedValues = [String: String]()

                // The values dictionary is [Key: Any]
                let valuesMirror = Mirror(reflecting: valuesChild.value)
                for child in valuesMirror.children {
                    // Each child is a key-value pair
                    if let pair = child.value as? (key: UVEnvironmentValues.Key, value: Any) {
                        let keyDescription = "\(pair.key.value)".components(separatedBy: ".").last ?? "\(pair.key.value)"
                        extractedValues[keyDescription] = "\(pair.value)"
                    }
                }
                self.values = extractedValues
            } else {
                self.values = [:]
            }

            // Check for parent
            if let parentChild = storageMirror.children.first(where: { $0.label == "parent" }) {
                self.hasParent = !(parentChild.value is NSNull)
            } else {
                self.hasParent = false
            }
        } else {
            self.values = [:]
            self.hasParent = false
        }
    }
}

// MARK: - Text Dump Support

public extension SystemSnapshot {
    /// Generate a human-readable text dump
    func textDump(includeEnvironment: Bool = false) -> String {
        var output = [String]()

        output.append("=== SYSTEM SNAPSHOT ===")
        output.append("Timestamp: \(timestamp)")
        output.append("Total Nodes: \(nodes.count)")
        output.append("Dirty Nodes: \(dirtyIdentifiers.count)")
        output.append("Active Stack Depth: \(activeNodeStackDepth)")
        output.append("")

        // Build hierarchy
        var nodesByIdentifier = [String: NodeSnapshot]()
        for node in nodes {
            nodesByIdentifier[node.identifier] = node
        }

        // Find root nodes (no parent)
        let rootNodes = nodes.filter { $0.parentIdentifier == nil }

        output.append("=== NODE HIERARCHY ===")
        for rootNode in rootNodes {
            output.append(contentsOf: dumpNode(rootNode, nodesByIdentifier: nodesByIdentifier, indent: 0, includeEnvironment: includeEnvironment))
        }

        if !dirtyIdentifiers.isEmpty {
            output.append("")
            output.append("=== DIRTY NODES ===")
            for identifier in dirtyIdentifiers.sorted() {
                output.append("  • \(identifier)")
            }
        }

        return output.joined(separator: "\n")
    }

    private func dumpNode(_ node: NodeSnapshot, nodesByIdentifier: [String: NodeSnapshot], indent: Int, includeEnvironment: Bool) -> [String] {
        var output = [String]()
        let indentStr = String(repeating: "  ", count: indent)

        // Node header
        let isDirty = dirtyIdentifiers.contains(node.identifier)
        let dirtyMarker = isDirty ? " [DIRTY]" : ""
        let setupMarker = node.needsSetup ? " [NEEDS SETUP]" : ""
        output.append("\(indentStr)• \(node.elementType)\(dirtyMarker)\(setupMarker)")
        output.append("\(indentStr)  ID: \(node.identifier)")

        // State properties
        if !node.stateProperties.isEmpty {
            output.append("\(indentStr)  State:")
            for prop in node.stateProperties {
                output.append("\(indentStr)    - \(prop.key): \(prop.value)")
                if !prop.dependencies.isEmpty {
                    output.append("\(indentStr)      deps: [\(prop.dependencies.joined(separator: ", "))]")
                }
            }
        }

        // Environment (optional)
        if includeEnvironment, !node.environmentValues.values.isEmpty {
            output.append("\(indentStr)  Environment:")
            for (key, value) in node.environmentValues.values.sorted(by: { $0.key < $1.key }) {
                output.append("\(indentStr)    - \(key): \(value)")
            }
        }

        // Find children
        let children = nodes.filter { $0.parentIdentifier == node.identifier }
        for child in children {
            output.append(contentsOf: dumpNode(child, nodesByIdentifier: nodesByIdentifier, indent: indent + 1, includeEnvironment: includeEnvironment))
        }

        return output
    }
}
