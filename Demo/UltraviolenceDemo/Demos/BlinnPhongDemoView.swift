import Metal
import MetalKit
import SwiftUI
import Ultraviolence
import UltraviolenceExamples
import UltraviolenceSupport

struct BlinnPhongDemoView: View {
    @State
    private var drawableSize: CGSize = .zero

//    @State
//    private var floorMesh = MTKMesh.plane().relabeled("floor")

    @State
    private var models: [Model] = [
        .init(id: "teapot", mesh: MTKMesh.teapot().relabeled("teapot"), modelMatrix: .identity, material: BlinnPhongMaterial(ambient: .color([0.5, 0.5, 0.5]), diffuse: .color([0.5, 0.5, 0.5]), specular: .color([0.5, 0.5, 0.5]), shininess: 1))
    ]


    @State
    private var lighting: BlinnPhongLighting

    @State
    private var lightPosition = simd_float3(5, 5, 5)

    let modelMatrix = simd_float4x4(translation: [0, 0, 0])
    let cameraMatrix = simd_float4x4(translation: [0, 2, 6])
    let projection = PerspectiveProjection()

    init() {
        do {
            let device = MTLCreateSystemDefaultDevice()!

            let lights = [
                BlinnPhongLight(lightPosition: [5, 5, 5], lightColor: [1, 1, 1], lightPower: 10)
            ]
            let lighting = BlinnPhongLighting(
                screenGamma: 2.2,
                ambientLightColor: [1, 1, 1],
                lights: try device.newTypedBuffer(values: lights, options: [])
            )
            self.lighting = lighting
        }
        catch {
            fatalError()
        }
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let projectionMatrix = projection.projectionMatrix(for: drawableSize)
            let transforms = Transforms(modelMatrix: modelMatrix, cameraMatrix: cameraMatrix, projectionMatrix: projectionMatrix)
            RenderView {
                try RenderPass {
                    try BlinnPhongShader(transforms: transforms) {
                        try ForEach(models) { model in
                            try Draw { encoder in
                                encoder.setVertexBuffers(of: model.mesh)
                                encoder.draw(model.mesh)
                            }
                            .blinnPhongMaterial(model.material)
                        }
                        .blinnPhongLighting(lighting)
                    }
                }
                .vertexDescriptor(MTLVertexDescriptor(MTKMesh.teapot().vertexDescriptor)) // TODO: Hack.
                .depthCompare(function: .less, enabled: true)
            }
            .metalDepthStencilPixelFormat(.depth32Float)
            .onDrawableSizeChange { drawableSize = $0 }
            .onChange(of: timeline.date) {
                let date = timeline.date.timeIntervalSinceReferenceDate
                let cycleDuration = 5.0

                let d = Float(date.truncatingRemainder(dividingBy: cycleDuration) / cycleDuration)

                let angle = 2 * .pi * d
                lighting.lights[0].lightPosition = [5 * cos(angle), 5, 5 * sin(angle)]

                lighting.lights[0].lightColor = [d, 1 - d, 0]
            }
        }
    }
}

extension BlinnPhongDemoView: DemoView {
}

struct Model: Identifiable {
    var id: String
    var mesh: MTKMesh
    var modelMatrix: float4x4
    var material: BlinnPhongMaterial
}

