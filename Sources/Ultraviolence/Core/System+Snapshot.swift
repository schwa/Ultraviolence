public import Foundation
internal import os

// MARK: - Snapshot Creation

public extension System {
    /// Create a snapshot of the current system state
    @MainActor
    func snapshot() -> SystemSnapshot {
        SystemSnapshot(system: self)
    }
    
    /// Create a snapshot and dump it to console
    @MainActor
    func dump(includeEnvironment: Bool = false) {
        let snapshot = self.snapshot()
        print(snapshot.textDump(includeEnvironment: includeEnvironment))
    }
    
}

// MARK: - Debug Logging

internal extension System {
    /// Log snapshot to OSLog for debugging
    @MainActor
    func logSnapshot(logger: Logger = Logger(subsystem: "Ultraviolence", category: "System")) {
        let snapshot = self.snapshot()
        
        logger.debug("=== System Snapshot ===")
        logger.debug("Nodes: \(snapshot.nodes.count)")
        logger.debug("Dirty: \(snapshot.dirtyIdentifiers.count)")
        logger.debug("Stack Depth: \(snapshot.activeNodeStackDepth)")
        
        // Log node hierarchy
        let rootNodes = snapshot.nodes.filter { $0.parentIdentifier == nil }
        for rootNode in rootNodes {
            logNode(rootNode, snapshot: snapshot, logger: logger, indent: 0)
        }
    }
    
    private func logNode(_ node: NodeSnapshot, snapshot: SystemSnapshot, logger: Logger, indent: Int) {
        let indentStr = String(repeating: "  ", count: indent)
        let isDirty = snapshot.dirtyIdentifiers.contains(node.identifier)
        let dirtyMarker = isDirty ? " [DIRTY]" : ""
        
        logger.debug("\(indentStr)• \(node.elementType)\(dirtyMarker) (\(node.identifier))")
        
        // Log state if present
        if !node.stateProperties.isEmpty {
            for prop in node.stateProperties {
                logger.debug("\(indentStr)  State.\(prop.key) = \(prop.value)")
            }
        }
        
        // Find and log children
        let children = snapshot.nodes.filter { $0.parentIdentifier == node.identifier }
        for child in children {
            logNode(child, snapshot: snapshot, logger: logger, indent: indent + 1)
        }
    }
}

// MARK: - StateBox Extension for Snapshot Support

internal protocol SnapshotValueProviding {
    var snapshotValue: Any { get }
}


extension StateBox: SnapshotValueProviding {
    /// Helper to create a snapshot-friendly representation
    internal var snapshotValue: Any {
        // Use Mirror to extract the value without triggering system checks
        let mirror = Mirror(reflecting: self)
        if let valueChild = mirror.children.first(where: { $0.label == "_value" }) {
            return valueChild.value
        }
        return "Unknown"
    }
}
