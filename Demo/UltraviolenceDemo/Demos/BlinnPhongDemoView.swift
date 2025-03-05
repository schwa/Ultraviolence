import Metal
import MetalKit
import simd
import SwiftUI
import Ultraviolence
import UltraviolenceExamples
import UltraviolenceSupport

struct BlinnPhongDemoView: View {
    @State
    private var drawableSize: CGSize = .zero

    @State
    private var models: [Model] = [
        .init(id: "teapot-1", mesh: MTKMesh.teapot().relabeled("teapot"), modelMatrix: .init(translation: [-2.5, 0, 0]), material: BlinnPhongMaterial(ambient: .color([0.5, 0.5, 0.5]), diffuse: .color([0.5, 0.5, 0.5]), specular: .color([0.5, 0.5, 0.5]), shininess: 1)),
        .init(id: "teapot-2", mesh: MTKMesh.teapot().relabeled("teapot"), modelMatrix: .init(translation: [2.5, 0, 0]), material: BlinnPhongMaterial(ambient: .color([0.5, 0.5, 0.5]), diffuse: .color([0.5, 0.5, 0.5]), specular: .color([0.5, 0.5, 0.5]), shininess: 1)),
        .init(id: "floor-1", mesh: MTKMesh.plane(width: 10, height: 10), modelMatrix: .init(xRotation: .degrees(270)), material: .init(ambient: .color([0.5, 0.5, 0.5]), diffuse: .color([0.5, 0.5, 0.5]), specular: .color([0.5, 0.5, 0.5]), shininess: 1))
    ]

    @State
    private var lighting: BlinnPhongLighting

    let lightMarker = MTKMesh.sphere(extent: [0.1, 0.1, 0.1]).relabeled("light-marker-0")

    let modelMatrix = simd_float4x4(translation: [0, 0, 0])
    let cameraMatrix = simd_float4x4(translation: [0, 2, 6])
    let projection = PerspectiveProjection()

    init() {
        do {
            let device = MTLCreateSystemDefaultDevice()!

            let lights = [
                BlinnPhongLight(lightPosition: [5, 5, 0], lightColor: [1, 0, 0], lightPower: 50)
            ]
            let lighting = BlinnPhongLighting(
                screenGamma: 2.2,
                ambientLightColor: [0, 0, 0],
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
            RenderView {
                let projectionMatrix = projection.projectionMatrix(for: drawableSize)
                try RenderPass {
                    let transforms = Transforms(modelMatrix: .init(translation: lighting.lights[0].lightPosition), cameraMatrix: cameraMatrix, projectionMatrix: projectionMatrix)

                    try FlatShader(transforms: transforms, textureSpecifier: .solidColor(SIMD4<Float>(lighting.lights[0].lightColor, 1))) {
                        Draw { encoder in
                            encoder.setVertexBuffers(of: lightMarker)
                            encoder.draw(lightMarker)
                        }
                    }
                    try BlinnPhongShader {
                        try ForEach(models) { model in
                            try Draw { encoder in
                                encoder.setVertexBuffers(of: model.mesh)
                                encoder.draw(model.mesh)
                            }
                            .blinnPhongMaterial(model.material)
                            .blinnPhongTransforms(.init(modelMatrix: model.modelMatrix, cameraMatrix: cameraMatrix, projectionMatrix: projectionMatrix))
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
                let angle = LinearTimingFunction().value(time: date, period: 1, in: 0 ... 2 * .pi)
                lighting.lights[0].lightPosition = simd_quatf(angle: angle, axis: [0, 1, 0]).act([1, 5, 0])
                lighting.lights[0].lightColor = [
                    ForwardAndReverseTimingFunction(SinusoidalTimingFunction()).value(time: date, period: 1.0, offset: 0.0, in: 0.5 ... 1.0),
                    ForwardAndReverseTimingFunction(SinusoidalTimingFunction()).value(time: date, period: 1.2, offset: 0.2, in: 0.5 ... 1.0),
                    ForwardAndReverseTimingFunction(SinusoidalTimingFunction()).value(time: date, period: 1.4, offset: 0.6, in: 0.5 ... 1.0)
                ]
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
