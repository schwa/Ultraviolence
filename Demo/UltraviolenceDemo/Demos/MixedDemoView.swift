import MetalKit
import simd
import SwiftUI
import Ultraviolence
import UltraviolenceExamples
import UltraviolenceSupport

struct MixedDemoView: View {
    @State
    private var angle: SwiftUI.Angle = .zero

    @State
    private var lightDirection: SIMD3<Float> = [-1, -2, -1]

    @State
    private var color: SIMD3<Float> = [1, 0, 0]

    var body: some View {
        let modelMatrix = simd_float4x4(yRotation: .init(radians: Float(angle.radians)))
        TimelineView(.animation) { timeline in
            RenderView {
                MixedExample(modelMatrix: modelMatrix, color: color, lightDirection: lightDirection)
                    .debugLabel("MIXED EXAMPLE")
            }
            .metalDepthStencilPixelFormat(.depth32Float)
            .metalFramebufferOnly(false)
            .metalDepthStencilAttachmentTextureUsage([.shaderRead, .renderTarget])
            .onChange(of: timeline.date) {
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

extension MixedDemoView: DemoView {
}
