import SwiftUI
import UltraviolenceSnapshotUI

@main
struct UltraviolenceExamplesApp: App {
    var body: some Scene {
        #if os(macOS)
        Window("Ultraviolence", id: "main") {
            ContentView()
        }
        #else
        WindowGroup("Ultraviolence", id: "main") {
            ContentView()
        }
        #endif

        SnapshotViewerDocumentScene()

        #if os(macOS)
        Settings {
            SettingsView()
        }
        #endif
    }
}
