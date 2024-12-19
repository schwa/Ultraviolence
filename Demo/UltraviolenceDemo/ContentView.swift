import MetalKit
import simd
import SwiftUI
import Ultraviolence
import UltraviolenceExamples
import UltraviolenceSupport

// swiftlint:disable force_try

struct ContentView: View {
    @SwiftUI.State
    var size: CGSize = .zero

    @SwiftUI.State
    var angle: SwiftUI.Angle = .zero

    var body: some View {
        let modelMatrix = simd_float4x4(yRotation: .init(radians: Float(angle.radians)))

//        RenderView(try! MyRenderPass(size: size, modelMatrix: modelMatrix))
        RenderView(try! TeapotDemo(modelMatrix: modelMatrix))
            .onGeometryChange(for: CGSize.self, of: \.size) { size = $0 }
            .overlay(alignment: .bottom) {
                VStack {
                    Slider(value: $angle.radians, in: 0...(.pi * 2))
                }
                .controlSize(.small)
                .frame(maxWidth: 320)
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                .padding()
            }
    }
}

#Preview {
    ContentView()
}
