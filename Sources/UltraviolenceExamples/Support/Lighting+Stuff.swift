import Metal
import SwiftUI
import Ultraviolence
import UltraviolenceSupport
import UltraviolenceExampleShaders
import MetalKit

struct LightingAnimator {
    static func run(date: Date, lighting: inout Lighting) {
        let date = date.timeIntervalSinceReferenceDate
        let angle = LinearTimingFunction().value(time: date, period: 1, in: 0 ... 2 * .pi)
        lighting.lights[Light.self, 0].color = [
            ForwardAndReverseTimingFunction(SinusoidalTimingFunction()).value(time: date, period: 1.0, offset: 0.0, in: 0.5 ... 1.0),
            ForwardAndReverseTimingFunction(SinusoidalTimingFunction()).value(time: date, period: 1.2, offset: 0.2, in: 0.5 ... 1.0),
            ForwardAndReverseTimingFunction(SinusoidalTimingFunction()).value(time: date, period: 1.4, offset: 0.6, in: 0.5 ... 1.0)
        ]
        lighting.lightPositions[SIMD3<Float>.self, 0] = simd_quatf(angle: angle, axis: [0, 1, 0]).act([1, 5, 0])
    }
}

extension Lighting {
    static func demo() throws -> Lighting {
        let device = _MTLCreateSystemDefaultDevice()
        let lights = [
            Light(type: .point, color: [1, 0, 0], intensity: 50)
        ]
        let positions = [
            SIMD3<Float>(1, 5, 0)
        ]
        assert(lights.count == positions.count)
        let lighting = Lighting(
            ambientLightColor: [0, 0, 0],
            count: lights.count,
            lights: try device.makeBuffer(view: .init(count: lights.count), values: lights, options: []),
            lightPositions: try device.makeBuffer(view: .init(count: positions.count), values: positions, options: [])
        )
        return lighting
    }
}

struct LightingVisualizer: Element {

    let cameraMatrix: float4x4
    let projectionMatrix: float4x4
    let lighting: Lighting
    let lightMarker = MTKMesh.sphere(extent: [0.1, 0.1, 0.1])

    var body: some Element {
        get throws {

            try FlatShader(textureSpecifier: .color([1, 1, 1])) {
                ForEach(Array(0 ..< lighting.count), id: \.self) { index in
                    let lightPosition = lighting.lightPositions[SIMD3<Float>.self, index]
                    let light = lighting.lights[Light.self, index]
                    let transforms = Transforms(modelMatrix: .init(translation: lightPosition), cameraMatrix: cameraMatrix, projectionMatrix: projectionMatrix)


                    Draw { encoder in
                        encoder.setVertexBuffers(of: lightMarker)
                        encoder.draw(lightMarker)
                    }
                    .transforms(transforms)
                }
            }
            .vertexDescriptor(lightMarker.vertexDescriptor)
            .depthCompare(function: .less, enabled: true)
        }
    }
}



struct LightingEditorView: View {

    @State
    var lighting: Lighting

    var body: some View {
    }
}
