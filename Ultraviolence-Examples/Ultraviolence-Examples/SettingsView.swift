#if os(macOS)
import AppKit
import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            Section("Debugging") {
                HStack {
                    Text("Snapshots Folder:")
                    Spacer()
                    Button("Reveal in Finder") {
                        revealSnapshotsFolder()
                    }
                }
                Text("Snapshots are saved when UV_DUMP_SNAPSHOTS environment variable is set")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 200)
    }

    private func revealSnapshotsFolder() {
        let directory = URL(fileURLWithPath: "/tmp/ultraviolence_snapshots")

        // Create directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: directory.path) {
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        }

        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: directory.path)
    }
}
#endif
