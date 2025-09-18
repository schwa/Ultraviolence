import Foundation

internal class Snapshotter {
    private struct FrameInfo: Codable {
        let number: Int
    }

    private struct SnapshotRecord: Codable {
        let frame: FrameInfo
        let snapshot: SystemSnapshot
    }

    private var frameCounter: Int = 0
    private let shouldDumpSnapshots = ProcessInfo.processInfo.environment["UV_DUMP_SNAPSHOTS"] != nil
    private var fileHandle: FileHandle?
    private let fileURL: URL

    init() {
        // Setup file path
        let baseDir = FileManager.default.temporaryDirectory.appendingPathComponent("ultraviolence_snapshots")
        let filename = "\(ProcessInfo.processInfo.processIdentifier).uvsnapshots"
        self.fileURL = baseDir.appendingPathComponent(filename)
    }

    deinit {
        fileHandle?.closeFile()
    }

    @MainActor
    func dumpSnapshotIfNeeded(_ system: System) {
        guard shouldDumpSnapshots else { return }

        frameCounter += 1

        // Create snapshot
        let snapshot = system.snapshot()

        // Create record with frame info and snapshot
        let record = SnapshotRecord(
            frame: FrameInfo(number: frameCounter),
            snapshot: snapshot
        )

        do {
            // Create directory if needed
            let directory = fileURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

            // Open file handle on first use
            if fileHandle == nil {
                // Create file if it doesn't exist
                if !FileManager.default.fileExists(atPath: fileURL.path) {
                    FileManager.default.createFile(atPath: fileURL.path, contents: nil)
                }
                fileHandle = try FileHandle(forWritingTo: fileURL)
                fileHandle?.seekToEndOfFile()

                print("UV_DUMP_SNAPSHOTS: Dumping snapshots to \(fileURL.path)")
            }

            // Encode record as single-line JSON and append newline
            let encoder = JSONEncoder()
            encoder.outputFormatting = [] // No pretty printing for JSONL
            let data = try encoder.encode(record)
            fileHandle?.write(data)
            fileHandle?.write("\n".data(using: .utf8)!)

            // Log progress
            if frameCounter == 1 || frameCounter % 100 == 0 {
                print("UV_DUMP_SNAPSHOTS: Saved frame \(frameCounter)")
            }
        } catch {
            print("UV_DUMP_SNAPSHOTS: Failed to save snapshot: \(error)")
        }
    }
}
