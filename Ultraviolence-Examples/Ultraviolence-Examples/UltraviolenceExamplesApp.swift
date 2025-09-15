import SwiftUI
import UltraviolenceSnapshotUI

@main
struct UltraviolenceExamplesApp: App {
    var body: some Scene {
        Window("Ultraviolence", id: "main") {
            ContentView()
        }

        SnapshotViewerDocumentScene()

        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}
