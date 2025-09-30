import SwiftUI
import Ultraviolence

internal struct SnapshotViewerDocumentView: View {
    @Binding var document: SnapshotViewerDocument
    @State private var selectedFrame: Int = 0

    var body: some View {
        Group {
            if let snapshot = document.currentSnapshot {
                SnapshotDebugView(snapshot: snapshot)
            } else {
                ContentUnavailableView("No Snapshot", systemImage: "doc.text.magnifyingglass", description: Text("Open a .uvsnapshots file to view"))
            }
        }
        .toolbar {
            ToolbarItemGroup {
                if !document.snapshots.isEmpty {
                    Button {
                        if selectedFrame > 0 {
                            selectedFrame -= 1
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .accessibilityLabel("Previous frame")
                    }
                    .disabled(selectedFrame == 0)
                    .keyboardShortcut(.leftArrow, modifiers: [])

                    Text("Frame:")

                    Picker("Frame", selection: $selectedFrame) {
                        ForEach(0..<document.snapshots.count, id: \.self) { index in
                            Text("\(document.snapshots[index].frame.number)")
                                .tag(index)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 100)

                    Button {
                        if selectedFrame < document.snapshots.count - 1 {
                            selectedFrame += 1
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .accessibilityLabel("Next frame")
                    }
                    .disabled(selectedFrame == document.snapshots.count - 1)
                    .keyboardShortcut(.rightArrow, modifiers: [])

                    Text("\(selectedFrame + 1) / \(document.snapshots.count)")
                        .monospacedDigit()
                }
            }
        }
        .onAppear {
            selectedFrame = document.currentFrameIndex
        }
        .onChange(of: selectedFrame) { _, newValue in
            document.currentFrameIndex = newValue
        }
    }
}
