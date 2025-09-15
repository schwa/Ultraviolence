import Foundation
#if os(macOS)
import AppKit
#endif

internal class Snapshotter {
    private var frameCounter: Int = 0
    #if os(macOS)
    private var hasRevealedDirectory = false
    #endif
    private let shouldDumpSnapshots = ProcessInfo.processInfo.environment["UV_DUMP_SNAPSHOTS"] != nil
    
    init() {
    }
    
    @MainActor
    func dumpSnapshotIfNeeded(_ system: System) {
        guard shouldDumpSnapshots else { return }
        
        frameCounter += 1
        
        // Create snapshot
        let snapshot = system.snapshot()
        
        // Setup directory - use user's temporary directory
        let baseDir = FileManager.default.temporaryDirectory.appendingPathComponent("ultraviolence_snapshots")
        let sessionDir = baseDir.appendingPathComponent(ProcessInfo.processInfo.processIdentifier.description)
        
        // Create directory if needed
        do {
            try FileManager.default.createDirectory(at: sessionDir, withIntermediateDirectories: true)
            
            // Reveal in Finder on first snapshot (macOS only)
            #if os(macOS)
            if !hasRevealedDirectory {
                hasRevealedDirectory = true
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: sessionDir.path)
            }
            #endif
            
            // Create filename with zero-padded frame number
            let filename = String(format: "frame_%06d.uvsnapshot", frameCounter)
            let fileURL = sessionDir.appendingPathComponent(filename)
            
            // Encode and save
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(snapshot)
            try data.write(to: fileURL)
            
            // Log first frame with full path, then every 100th frame
            if frameCounter == 1 {
                print("UV_DUMP_SNAPSHOTS: Dumping snapshots to \(sessionDir.path)")
                print("UV_DUMP_SNAPSHOTS: Saved frame \(frameCounter) to \(fileURL.path)")
            } else if frameCounter % 100 == 0 {
                print("UV_DUMP_SNAPSHOTS: Saved frame \(frameCounter) to \(fileURL.path)")
            }
        } catch {
            print("UV_DUMP_SNAPSHOTS: Failed to save snapshot: \(error)")
        }
    }
}