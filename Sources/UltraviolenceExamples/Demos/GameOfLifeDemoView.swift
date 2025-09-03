import SwiftUI
import Ultraviolence
import UltraviolenceUI

public struct GameOfLifeDemoView: View {
    @State private var isRunning = true
    @State private var pattern: GameOfLife.InitialPattern = .random
    @State private var updateInterval: Double = 2.0
    @State private var gridSize = 256
    
    public init() {
        // This line intentionally left blank.
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Render view
            RenderView {
                GameOfLife(
                    gridSize: (width: gridSize, height: gridSize),
                    updateInterval: Int(updateInterval),
                    isRunning: isRunning,
                    pattern: pattern
                )
            }
            .background(Color.black)
            
            // Controls
            VStack(spacing: 12) {
                // Playback controls
                HStack(spacing: 20) {
                    Button(action: { isRunning.toggle() }) {
                        Image(systemName: isRunning ? "pause.fill" : "play.fill")
                            .font(.title2)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Text("Update every \(Int(updateInterval)) frames")
                        .frame(width: 150)
                    
                    Slider(value: $updateInterval, in: 1...10, step: 1)
                        .frame(width: 200)
                }
                
                // Pattern controls
                HStack(spacing: 20) {
                    Text("Pattern:")
                    
                    Button("Glider") {
                        pattern = .glider
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Random") {
                        pattern = .random
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Clear") {
                        pattern = .clear
                        isRunning = false
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Text("Grid: \(gridSize)x\(gridSize)")
                    
                    Picker("Grid Size", selection: $gridSize) {
                        Text("128").tag(128)
                        Text("256").tag(256)
                        Text("512").tag(512)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }
                
                // Info text
                Text("Conway's Game of Life - GPU Compute Shader Demo")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(white: 0.1))
        }
    }
}

extension GameOfLifeDemoView: DemoView {
    public static var keywords: [String] {
        ["Compute", "Simulation", "Game of Life", "Cellular Automaton"]
    }
}

// Preview
struct GameOfLifeDemoView_Previews: PreviewProvider {
    static var previews: some View {
        GameOfLifeDemoView()
    }
}