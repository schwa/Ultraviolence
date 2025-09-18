import SwiftUI
import UltraviolenceUI

public struct GameOfLifeDemoView: View {
    @State private var isRunning = true
    @State private var pattern: GameOfLife.InitialPattern = .random

    public init() {
        // This line intentionally left blank.
    }

    public var body: some View {
        // Render view
        RenderView { _, _ in
            GameOfLife(isRunning: isRunning, pattern: pattern)
        }

        .overlay(alignment: .bottom) {
            HStack {
                Button(action: { isRunning.toggle() }) {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                }

                Menu("Fill") {
                    Button("Glider") {
                        pattern = .glider
                    }

                    Button("Random") {
                        pattern = .random
                    }

                    Button("Clear") {
                        pattern = .clear
                    }
                }
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            .padding()
        }
    }
}
