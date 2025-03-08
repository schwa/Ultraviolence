import simd
import SwiftUI
import UltraviolenceSupport

struct WorldView<Content: View>: View {
    var content: (_ projection: any ProjectionProtocol, _ cameraMatrix: simd_float4x4) -> Content
    var projection: any ProjectionProtocol
    @State
    private var cameraRotation: simd_quatf = .identity

    @State
    private var angle: Angle = .zero

    init(projection: any ProjectionProtocol = PerspectiveProjection(),
         @ViewBuilder content: @escaping (_ projection: any ProjectionProtocol, _ cameraMatrix: simd_float4x4) -> Content) {
        self.projection = projection
        self.content = content
    }

    var body: some View {
        content(projection, .init(cameraRotation))
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
            .onChange(of: angle) {
                cameraRotation = simd_quatf(angle: Float(angle.radians), axis: [0, 1, 0])
            }
    }
}
