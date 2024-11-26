// import simd
// import SwiftUI
// import Ultraviolence
// import UltraviolenceExamples
// internal import UltraviolenceSupport
// import UltraviolenceUI
//
// public struct MixedExampleView: View {
//    @State
//    private var color: SIMD4<Float> = [1, 0, 0, 1]
//
//    @State
//    private var size: CGSize = .zero
//
//    @State
//    private var angle: UltraviolenceSupport.Angle = .zero
//
//    @State
//    private var camera: SIMD3<Float> = [0, 2, 6]
//
//    public init() {
//    }
//
//    public var body: some View {
//        TimelineView(.animation) { timeline in
//            RenderView { renderPassDescriptor in
//                // TODO: How do we get the color and depth textures? We need to get the currentRenderPassDescriptor from the RenderView
//
//                let colorTexture = renderPassDescriptor.colorAttachments[0].texture!
//                let depthTexture = renderPassDescriptor.depthAttachment!.texture!
//                return MixedExample(size: size, geometries: [Teapot()], colorTexture: colorTexture, depthTexture: depthTexture, camera: camera, model: simd_float4x4(yRotation: angle))
//            }
//            .onGeometryChange(for: CGSize.self, of: \.size) { size = $0 }
//            .onChange(of: timeline.date, initial: true) {
//                angle = UltraviolenceSupport.Angle(degrees: Float((timeline.date.timeIntervalSince1970 * 120).truncatingRemainder(dividingBy: 360)))
//            }
//        }
//    }
// }
