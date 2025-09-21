import SwiftUI
import Ultraviolence
import UltraviolenceSupport
import GeometryLite3D
import simd
import UltraviolenceUI
import Metal

public struct SceneGraphDemoView: View {

    let sceneGraph: SceneGraph

    @State
    var projection: any ProjectionProtocol = PerspectiveProjection()

    @State
    var cameraMatrix: simd_float4x4 = simd_float4x4(translation: [0, 2, 5])

    public init() {
        let device = _MTLCreateSystemDefaultDevice()
        sceneGraph = SceneGraph.demo(device: device)
    }

    public var body: some View {
        WorldView(projection: $projection, cameraMatrix: $cameraMatrix, targetMatrix: .constant(nil)) {
            RenderView { conext, drawableSize in
                SceneGraphRenderPass(sceneGraph: sceneGraph, cameraMatrix: cameraMatrix, projectionMatrix: projection.projectionMatrix(for: drawableSize))
            }
            .metalDepthStencilPixelFormat(.depth32Float)
        }

    }
}
