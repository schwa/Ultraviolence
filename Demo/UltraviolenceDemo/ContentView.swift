import MetalKit
import simd
import SwiftUI
import Ultraviolence
import UltraviolenceExamples
import UltraviolenceSupport

struct ContentView: View {
    @SwiftUI.State
    var angle: SwiftUI.Angle = .zero

    var body: some View {
        let modelMatrix = simd_float4x4(yRotation: .init(radians: Float(angle.radians)))
        TimelineView(.animation) { _ in
            RenderView { drawable, renderPassDescriptor in
                let colorTexture = renderPassDescriptor.colorAttachments[0].texture.orFatalError()
                let depthTexture = renderPassDescriptor.depthAttachment.texture.orFatalError()
                return MixedExample(drawableSize: .init(drawable.layer.drawableSize), colorTexture: colorTexture, depthTexture: depthTexture, modelMatrix: modelMatrix)
            }
        }
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
