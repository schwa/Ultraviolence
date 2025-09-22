import Metal
import Ultraviolence
import UltraviolenceExampleShaders
import UltraviolenceSupport

struct Lighting {
    var ambientLightColor: simd_float3
    var count: Int
    var lights: MTLBuffer
    var lightPositions: MTLBuffer
}

extension Lighting {
    func toArgumentBuffer() throws -> LightingArgumentBuffer {
        return LightingArgumentBuffer(
            ambientLightColor: ambientLightColor,
            lightCount: Int32(count),
            lights: lights.gpuAddressAsUnsafeMutablePointer(type: Light.self).orFatalError(),
            lightPositions: lightPositions.gpuAddressAsUnsafeMutablePointer(type: SIMD3<Float>.self).orFatalError()
        )
    }
}

extension Element {
    func lighting(_ lighting: Lighting) throws -> some Element {
        self
        .parameter("lighting", value: try lighting.toArgumentBuffer())
        .useResource(lighting.lights, usage: .read, stages: .fragment)
        .useResource(lighting.lightPositions, usage: .read, stages: .fragment)
    }
}
