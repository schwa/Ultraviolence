import Metal
import MetalKit
import simd
import SwiftUI
import Ultraviolence
import UltraviolenceSupport
import UltraviolenceUI

public struct BlinnPhongDemoView: View {
    @State
    private var models: [Model] = [
        .init(id: "teapot-1", mesh: MTKMesh.teapot().relabeled("teapot"), modelMatrix: .init(translation: [-2.5, 0, 0]), material: BlinnPhongMaterial(ambient: .color([0.5, 0.5, 0.5]), diffuse: .color([0.5, 0.5, 0.5]), specular: .color([0.5, 0.5, 0.5]), shininess: 1)),
        .init(id: "teapot-2", mesh: MTKMesh.teapot().relabeled("teapot"), modelMatrix: .init(translation: [2.5, 0, 0]), material: BlinnPhongMaterial(ambient: .color([0.5, 0.5, 0.5]), diffuse: .color([0.5, 0.5, 0.5]), specular: .color([0.5, 0.5, 0.5]), shininess: 1)),
        .init(id: "floor-1", mesh: MTKMesh.plane(width: 10, height: 10), modelMatrix: .init(xRotation: .degrees(270)), material: .init(ambient: .color([0.5, 0.5, 0.5]), diffuse: .color([0.5, 0.5, 0.5]), specular: .color([0.5, 0.5, 0.5]), shininess: 1))
    ]

    @State
    private var lighting: BlinnPhongLighting

    @State
    private var skyboxTexture: MTLTexture

    let lightMarker = MTKMesh.sphere(extent: [0.1, 0.1, 0.1]).relabeled("light-marker-0")

    @State
    private var projection: any ProjectionProtocol = PerspectiveProjection()

    @State
    private var cameraMatrix: simd_float4x4 = .init(translation: [0, 2, 6])

    @State
    private var drawableSize: CGSize = .zero

    public init() {
        do {
            let device = _MTLCreateSystemDefaultDevice()

            let lights = [
                BlinnPhongLight(lightPosition: [5, 5, 0], lightColor: [1, 0, 0], lightPower: 50)
            ]
            let lighting = BlinnPhongLighting(
                ambientLightColor: [0, 0, 0],
                lights: try device.makeTypedBuffer(values: lights, options: [])
            )
            self.lighting = lighting

            self.skyboxTexture = try! device.makeTextureCubeFromCrossTexture(texture: try device.makeTexture(name: "Skybox", bundle: .main))
        }
        catch {
            fatalError("\(error)")
        }
    }

    public var body: some View {
        WorldView(projection: $projection, cameraMatrix: $cameraMatrix, targetMatrix: .constant(nil)) {
            TimelineView(.animation) { timeline in
                RenderView {
                    let projectionMatrix = projection.projectionMatrix(for: drawableSize)

                    try RenderPass {
                        try SkyboxRenderPipeline(projectionMatrix: projectionMatrix, cameraMatrix: cameraMatrix, texture: skyboxTexture)

                        GridShader(projectionMatrix: projection.projectionMatrix(for: drawableSize), cameraMatrix: cameraMatrix)

                        let transforms = Transforms(modelMatrix: .init(translation: lighting.lights[0].lightPosition), cameraMatrix: cameraMatrix, projectionMatrix: projectionMatrix)
                        try FlatShader(textureSpecifier: .color(SIMD3<Float>(lighting.lights[0].lightColor))) {
                            Draw { encoder in
                                encoder.setVertexBuffers(of: lightMarker)
                                encoder.draw(lightMarker)
                            }
                            .transforms(transforms)
                        }
                        .vertexDescriptor(MTLVertexDescriptor(MTKMesh.teapot().vertexDescriptor)) // TODO: #125 Hack.
                        .depthCompare(function: .less, enabled: true)

                        try BlinnPhongShader {
                            try ForEach(models) { model in
                                try Draw { encoder in
                                    encoder.setVertexBuffers(of: model.mesh)
                                    encoder.draw(model.mesh)
                                }
                                .blinnPhongMaterial(model.material)
                                .transforms(.init(modelMatrix: model.modelMatrix, cameraMatrix: cameraMatrix, projectionMatrix: projectionMatrix))
                            }
                            .blinnPhongLighting(lighting)
                        }
                        .vertexDescriptor(MTLVertexDescriptor(MTKMesh.teapot().vertexDescriptor)) // TODO: #125 Hack.
                        .depthCompare(function: .less, enabled: true)
                    }
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
            .modifier(RTSControllerModifier(cameraMatrix: $cameraMatrix))
        }
    }
}

extension BlinnPhongDemoView: DemoView {
    public static var keywords: [String] {
        ["Raster", "Lighting"]
    }
    public static var demoDescription: String? {
        "A demo of Blinn-Phong lighting with multiple models."
    }

}

struct Model: Identifiable {
    var id: String
    var mesh: MTKMesh
    var modelMatrix: float4x4
    var material: BlinnPhongMaterial
}
