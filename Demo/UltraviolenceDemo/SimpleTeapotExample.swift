import simd
import Ultraviolence
import BaseSupport
import SwiftUI
import Examples

public struct SimpleTeapotExample: View {

    @State
    var color: SIMD4<Float> = [1, 0, 0, 1]

    @State
    var size: CGSize = .zero

    @State
    var angle: Angle = .zero

    @State
    var camera: SIMD3<Float> = [0, 2, 6]

    public init() {
    }

    public var body: some View {
        TimelineView(.animation) { timeline in
            RenderView(TeapotRenderPass(
                color: color,
                size: size,
                model: simd_float4x4(yRotation: angle),
                view: simd_float4x4(translation: camera).inverse,
                cameraPosition: camera)
            )
            .onGeometryChange(for: CGSize.self, of: \.size, action: { size = $0 })
            .onChange(of: timeline.date, initial: true) {
                angle = Angle(degrees: (timeline.date.timeIntervalSince1970 * 120).truncatingRemainder(dividingBy: 360))
            }
        }
    }
}
