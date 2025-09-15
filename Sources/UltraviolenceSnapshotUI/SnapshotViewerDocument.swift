import SwiftUI
import Ultraviolence
import UniformTypeIdentifiers

public struct SnapshotViewerDocumentScene: Scene {
    public init() {
    }

    public var body: some Scene {
        DocumentGroup(viewing: SnapshotViewerDocument.self) { file in
            SnapshotViewerDocumentView(document: file.$document)
        }
    }
}


nonisolated struct SnapshotViewerDocument: FileDocument {
    struct FrameInfo: Codable {
        let number: Int
    }
    
    struct SnapshotRecord: Codable {
        let frame: FrameInfo
        let snapshot: SystemSnapshot
    }
    
    var snapshots: [SnapshotRecord]
    var currentFrameIndex: Int = 0
    
    @MainActor
    var currentSnapshot: SystemSnapshot? {
        guard !snapshots.isEmpty else {
            return nil
        }
        let index = min(max(0, currentFrameIndex), snapshots.count - 1)
        return snapshots[index].snapshot
    }

    init(snapshots: [SnapshotRecord]) {
        self.snapshots = snapshots
        self.currentFrameIndex = 0
    }

    @MainActor
    init() {
        // Initialize with empty snapshots - no System creation
        self.snapshots = []
        self.currentFrameIndex = 0
    }

    static let readableContentTypes = [
        UTType(importedAs: "io.schwa.uvsnapshots")
    ]

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        // Read all lines of the JSONL file
        guard let fileContent = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        let lines = fileContent.components(separatedBy: .newlines)
            .filter { !$0.isEmpty }
        
        var records: [SnapshotRecord] = []
        for line in lines {
            guard let lineData = line.data(using: .utf8) else {
                continue
            }
            do {
                let record = try JSONDecoder().decode(SnapshotRecord.self, from: lineData)
                records.append(record)
            } catch {
                // Skip malformed lines
                continue
            }
        }
        
        guard !records.isEmpty else {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        self.snapshots = records
        self.currentFrameIndex = 0
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        // Save all snapshots as JSONL
        let encoder = JSONEncoder()
        encoder.outputFormatting = []
        
        var lines: [String] = []
        for record in snapshots {
            let data = try encoder.encode(record)
            if let line = String(data: data, encoding: .utf8) {
                lines.append(line)
            }
        }
        
        let content = lines.joined(separator: "\n")
        guard let data = content.data(using: .utf8) else {
            throw CocoaError(.fileWriteUnknown)
        }
        
        return .init(regularFileWithContents: data)
    }
}
