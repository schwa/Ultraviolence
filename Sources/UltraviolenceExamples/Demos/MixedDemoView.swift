import DemoKit
import MetalKit
import simd
import SwiftUI
import Ultraviolence
import UltraviolenceSupport
import UltraviolenceUI
import GeometryLite3D

public struct MixedDemoView: View {
    @State
    private var projection: any ProjectionProtocol = PerspectiveProjection()

    @State
    private var cameraMatrix: simd_float4x4 = .init(translation: [0, 2, 6])

    @State
    private var lightDirection: SIMD3<Float> = [-1, -2, -1]

    @State
    private var color: SIMD3<Float> = [1, 0, 0]

    @State
    private var angle: Angle = .zero

    @State
    private var drawableSize: CGSize = .zero

    public init() {
        // This line intentionally left blank.
    }

    public var body: some View {
        let modelMatrix = simd_float4x4(yRotation: .init(radians: Float(angle.radians)))
        WorldView(projection: $projection, cameraMatrix: $cameraMatrix) {
            TimelineView(.animation) { timeline in
                RenderView {
                    let transforms = Transforms(modelMatrix: modelMatrix, cameraMatrix: cameraMatrix, projectionMatrix: projection.projectionMatrix(for: drawableSize))
                    MixedExample(transforms: transforms, color: color, lightDirection: lightDirection)
                    //                        .debugLabel("MIXED EXAMPLE")
                }
                .metalDepthStencilPixelFormat(.depth32Float)
                .metalFramebufferOnly(false)
                .metalDepthStencilAttachmentTextureUsage([.shaderRead, .renderTarget])
                .onChange(of: timeline.date) {
                    let degreesPerSecond = 90.0
                    let angle = Angle(degrees: (degreesPerSecond * timeline.date.timeIntervalSince1970).truncatingRemainder(dividingBy: 360))
                    lightDirection = SIMD3<Float>(sin(Float(angle.radians)), -2, cos(Float(angle.radians)))
                }
                .onDrawableSizeChange { drawableSize = $0 }
            }
        }
    }
}

extension MixedDemoView: DemoView {
    public static var metadata: DemoMetadata {
        DemoMetadata(
            name: "Mixed Techniques",
            description: "Combination of multiple rendering techniques including lighting and animation",
            keywords: ["multipass"]
        )
    }
}
