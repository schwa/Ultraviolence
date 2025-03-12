import simd
import SwiftUI

internal struct SlidersOverlayCameraController: ViewModifier {
    @State
    var pitch: AngleF = .zero

    @State
    var yaw: AngleF = .zero

    @Binding
    var rotation: simd_quatf

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                VStack {
                    HStack {
                        Slider(value: $pitch.degrees, in: -90...90) { Text("Pitch") }
                        TextField("Pitch", value: $pitch.degrees, formatter: NumberFormatter())
                    }
                    HStack {
                        Slider(value: $yaw.degrees, in: 0...360) { Text("Yaw") }
                        TextField("Yaw", value: $yaw.degrees, formatter: NumberFormatter())
                    }
                }
                .controlSize(.small)
                .frame(maxWidth: 320)
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
                .padding()
            }
            .onChange(of: [yaw, pitch], initial: true) {
                let yaw = simd_quatf(angle: Float(yaw.radians), axis: [0, 1, 0])
                let pitch = simd_quatf(angle: Float(pitch.radians), axis: [1, 0, 0])
                rotation = yaw * pitch
            }
    }
}

extension View {
    func slidersOverlayCameraController(rotation: Binding<simd_quatf>) -> some View {
        modifier(SlidersOverlayCameraController(rotation: rotation))
    }
}
