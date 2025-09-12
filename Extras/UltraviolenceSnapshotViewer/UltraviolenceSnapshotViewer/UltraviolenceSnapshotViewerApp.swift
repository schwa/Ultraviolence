import SwiftUI


@main
struct UltraviolenceSnapshotViewerApp: App {

    let emptyDocument: UltraviolenceSnapshotViewerDocument

    init() {
        emptyDocument = UltraviolenceSnapshotViewerDocument()
    }

    var body: some Scene {
        DocumentGroup(newDocument: emptyDocument) { file in
            ContentView(document: file.$document)
        }
    }
}
