import SwiftUI
import Ultraviolence
import UltraviolenceSnapshotUI

struct ContentView: View {
    @Binding var document: UltraviolenceSnapshotViewerDocument

    var body: some View {
        SnapshotDebugView(snapshot: document.snapshot)
    }
}

#Preview {
    ContentView(document: .constant(UltraviolenceSnapshotViewerDocument()))
}

