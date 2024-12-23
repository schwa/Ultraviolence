import MetalKit
import simd
import SwiftUI
import Ultraviolence
import UltraviolenceExamples
import UltraviolenceSupport

struct ContentView: View {
    @SwiftUI.State
    var angle: SwiftUI.Angle = .zero

    @SwiftUI.State
    var lightDirection: SIMD3<Float> = [-1, -2, -1]

    @SwiftUI.State
    var color: SIMD4<Float> = [1, 0, 0, 1]

    var body: some View {
        let modelMatrix = simd_float4x4(yRotation: .init(radians: Float(angle.radians)))
        TimelineView(.animation) { timeline in
            RenderView { drawable, renderPassDescriptor in
                let colorTexture = renderPassDescriptor.colorAttachments[0].texture.orFatalError()
                let depthTexture = renderPassDescriptor.depthAttachment.texture.orFatalError()
                return MixedExample(drawableSize: .init(drawable.layer.drawableSize), colorTexture: colorTexture, depthTexture: depthTexture, modelMatrix: modelMatrix, color: color, lightDirection: lightDirection)
            }
            .onChange(of: timeline.date) {
                // degrees per second
                let degreesPerSecond = 90.0
                let angle = Angle(degrees: (degreesPerSecond * timeline.date.timeIntervalSince1970).truncatingRemainder(dividingBy: 360))
                lightDirection = SIMD3<Float>(sin(Float(angle.radians)), -2, cos(Float(angle.radians)))
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
