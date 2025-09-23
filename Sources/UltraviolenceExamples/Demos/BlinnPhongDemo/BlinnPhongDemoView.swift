import GeometryLite3D
import Metal
import MetalKit
import simd
import SwiftUI
import Ultraviolence
import UltraviolenceSupport
import UltraviolenceUI
import UltraviolenceExampleShaders

public struct BlinnPhongDemoView: View {
    @State
    private var models: [Model] = [
        .init(id: "teapot-1", mesh: MTKMesh.teapot().relabeled("teapot"), modelMatrix: .init(translation: [-2.5, 0, 0]), material: BlinnPhongMaterial(ambient: .color([0.5, 0.5, 0.5]), diffuse: .color([0.5, 0.5, 0.5]), specular: .color([0.5, 0.5, 0.5]), shininess: 1)),
        .init(id: "teapot-2", mesh: MTKMesh.teapot().relabeled("teapot"), modelMatrix: .init(translation: [2.5, 0, 0]), material: BlinnPhongMaterial(ambient: .color([0.5, 0.5, 0.5]), diffuse: .color([0.5, 0.5, 0.5]), specular: .color([0.5, 0.5, 0.5]), shininess: 1)),
        .init(id: "floor-1", mesh: MTKMesh.plane(width: 10, height: 10), modelMatrix: .init(xRotation: .degrees(270)), material: .init(ambient: .color([0.5, 0.5, 0.5]), diffuse: .color([0.5, 0.5, 0.5]), specular: .color([0.5, 0.5, 0.5]), shininess: 1))
    ]

    @State
    private var lighting: Lighting
    @State
    private var skyboxTexture: MTLTexture
    @State
    private var projection: any ProjectionProtocol = PerspectiveProjection()
    @State
    private var cameraMatrix: simd_float4x4 = .init(translation: [0, 2, 6])

    public init() {
        do {
            self.lighting = try! .demo()
            let device = _MTLCreateSystemDefaultDevice()
            self.skyboxTexture = try! device.makeTextureCubeFromCrossTexture(texture: try device.makeTexture(name: "Skybox", bundle: .main))
        }
        catch {
            fatalError("\(error)")
        }
    }

    public var body: some View {
        WorldView(projection: $projection, cameraMatrix: $cameraMatrix, targetMatrix: .constant(nil)) {
            TimelineView(.animation) { timeline in
                RenderView { _, drawableSize in
                    let projectionMatrix = projection.projectionMatrix(for: drawableSize)
                    let viewMatrix = cameraMatrix.inverse
                    let viewProjectionMatrix = projectionMatrix * viewMatrix

                    try RenderPass {
                        try SkyboxRenderPipeline(projectionMatrix: projectionMatrix, cameraMatrix: cameraMatrix, texture: skyboxTexture)

                        GridShader(projectionMatrix: projectionMatrix, cameraMatrix: cameraMatrix)

                        LightingVisualizer(cameraMatrix: cameraMatrix, projectionMatrix: projectionMatrix, lighting: lighting)

                        try BlinnPhongShader {
                            try ForEach(models) { model in
                                try Draw { encoder in
                                    encoder.setVertexBuffers(of: model.mesh)
                                    encoder.draw(model.mesh)
                                }
                                .blinnPhongMaterial(model.material)
                                .transforms(.init(modelMatrix: model.modelMatrix, cameraMatrix: cameraMatrix, projectionMatrix: projectionMatrix))
                            }
                            .lighting(lighting)
                        }
                        .vertexDescriptor(models.first!.mesh.vertexDescriptor)
                        .depthCompare(function: .less, enabled: true)

                        try AxisLinesRenderPipeline(mvpMatrix: viewProjectionMatrix, scale: 10_000.0)
                    }
                }
                .metalDepthStencilPixelFormat(.depth32Float)
                .onChange(of: timeline.date) {
                    LightingAnimator.run(date: timeline.date, lighting: &lighting)
                }
            }
        }
    }
}

struct Model: Identifiable {
    var id: String
    var mesh: MTKMesh
    var modelMatrix: float4x4
    var material: BlinnPhongMaterial
}
