import simd
import SwiftUI
import Ultraviolence
import UltraviolenceExamples
internal import UltraviolenceSupport
import UltraviolenceUI

public struct SimpleTeapotExample: View {
    @State
    private var color: SIMD4<Float> = [1, 0, 0, 1]

    @State
    private var size: CGSize = .zero

    @State
    private var angle: UltraviolenceSupport.Angle = .zero

    @State
    private var camera: SIMD3<Float> = [0, 2, 6]

    public init() {
    }

    public var body: some View {
        TimelineView(.animation) { timeline in
            RenderView { _ in
                Render {
                    TeapotRenderPass(color: color, size: size, model: simd_float4x4(yRotation: angle), view: simd_float4x4(translation: camera).inverse, cameraPosition: camera)
                }
            }
            .onGeometryChange(for: CGSize.self, of: \.size) { size = $0 }
            .onChange(of: timeline.date, initial: true) {
                angle = UltraviolenceSupport.Angle(degrees: Float((timeline.date.timeIntervalSince1970 * 120).truncatingRemainder(dividingBy: 360)))
            }
        }
    }
}
