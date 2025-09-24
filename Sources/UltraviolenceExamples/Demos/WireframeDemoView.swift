import GeometryLite3D
import Metal
import MetalKit
import simd
import SwiftUI
import Ultraviolence
import UltraviolenceExampleShaders
import UltraviolenceSupport
import UltraviolenceUI

public struct WireframeDemoView: View {
    @State
    private var wireframeColor: SIMD4<Float> = [0, 1, 0, 1]

    @State
    private var rotationAngle: Float = 0

    @State
    private var projection: any ProjectionProtocol = PerspectiveProjection()

    @State
    private var cameraMatrix: simd_float4x4 = .init(translation: [0, 2, 6])

    let teapotMesh = MTKMesh.teapot().relabeled("wireframe-teapot")

    public init() {
    }

    public var body: some View {
        WorldView(projection: $projection, cameraMatrix: $cameraMatrix, targetMatrix: .constant(nil)) {
            RenderView { _, drawableSize in
                let projectionMatrix = projection.projectionMatrix(for: drawableSize)
                let viewMatrix = cameraMatrix.inverse
                let modelMatrix = float4x4.identity
                let mvpMatrix = projectionMatrix * viewMatrix * modelMatrix

                try RenderPass {
                    GridShader(projectionMatrix: projectionMatrix, cameraMatrix: cameraMatrix)
                    try AxisLinesRenderPipeline(mvpMatrix: projectionMatrix * viewMatrix, scale: 10_000.0)
                    try WireframeRenderPipeline(mvpMatrix: mvpMatrix, wireframeColor: wireframeColor, mesh: teapotMesh)
                }
            }
            .metalDepthStencilPixelFormat(.depth32Float)
        }
    }
}
