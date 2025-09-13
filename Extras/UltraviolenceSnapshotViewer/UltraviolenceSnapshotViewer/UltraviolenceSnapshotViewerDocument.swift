import SwiftUI
import Ultraviolence
import UltraviolenceSnapshotUI
import UniformTypeIdentifiers

nonisolated struct UltraviolenceSnapshotViewerDocument: FileDocument {
    var snapshot: SystemSnapshot

    @MainActor
    static let emptySnapshot: SystemSnapshot = {
        let root = EmptyElement()
        let system = System()
        try! system.update(root: root)
        return system.snapshot()
    }()

    @MainActor
    static let complexSnapshot: SystemSnapshot = {
        struct DemoElement: Element {
            @UVState
            var count = 0

            var body: some Element {
                EmptyElement()
            }
        }

        let root = DemoElement()
        let system = System()
        try! system.update(root: DemoElement())
        return system.snapshot()
    }()

    init(snapshot: SystemSnapshot) {
        self.snapshot = snapshot
    }

    @MainActor
    init() {
        snapshot = Self.complexSnapshot
    }

    static let readableContentTypes = [
        UTType(importedAs: "io.schwa.uvsnapshot")
    ]

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        snapshot = try JSONDecoder().decode(SystemSnapshot.self, from: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        let data = try encoder.encode(snapshot)
        return .init(regularFileWithContents: data)
    }
}
