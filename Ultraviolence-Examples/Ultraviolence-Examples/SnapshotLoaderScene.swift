import SwiftUI
import Ultraviolence
import UltraviolenceSnapshotUI
import UniformTypeIdentifiers

struct SnapshotLoaderScene: Scene {
    @Environment(\.openWindow)
    var openWindow

    var body: some Scene {
        Window("Snapshot Loader", id: "snapshot-loader") {
            SnapshotLoaderView()
        }
        .commands {
            CommandGroup(before: .appSettings) {
                Button("Snapshots") {
                    openWindow(id: "snapshot-loader")
                }
                .keyboardShortcut("s", modifiers: [.command, .shift] )
            }
        }
    }
}

struct SnapshotLoaderView: View {

    @State
    var snapshot: SystemSnapshot?

    @State
    var isFileImporterPresented = false

    var body: some View {
        ZStack {
            if let snapshot {
                SnapshotDebugView(snapshot: snapshot)
            }
            else {
                ContentUnavailableView {
                    Text("Load a snapshot…")
                }
                actions: {
                    Button("Load") {
                        isFileImporterPresented = true
                    }
                    .fileImporter(isPresented: $isFileImporterPresented, allowedContentTypes: [.uvSnapshot]) { result in
                        guard case .success(let url) = result else {
                            return
                        }
                        let data = try! Data(contentsOf: url)
                        let decoder = JSONDecoder()
                        self.snapshot = try! decoder.decode(SystemSnapshot.self, from: data)
                    }

                }
            }
        }
    }
}

extension UTType {
    static let uvSnapshot = UTType(filenameExtension: "uvsnapshot")!
}
