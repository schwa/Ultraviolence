import Metal
import Ultraviolence
import UltraviolenceExampleShaders
import UltraviolenceSupport

extension Light {
    init(type: LightType, color: SIMD3<Float> = [1, 1, 1], intensity: Float = 1.0) {
        self.init(type: type, color: color, intensity: intensity, range: .infinity)
    }
}

struct Lighting {
    var ambientLightColor: simd_float3
    var count: Int
    var lights: MTLBuffer
    var lightPositions: MTLBuffer
}

extension Lighting {
    init(ambientLightColor: SIMD3<Float>, lights: [(SIMD3<Float>, Light)], capacity: Int? = nil) throws {
        assert(!lights.isEmpty)
        let device = _MTLCreateSystemDefaultDevice()
        self.ambientLightColor = ambientLightColor
        self.count = lights.count
        let capacity = capacity ?? lights.count
        self.lights = try device.makeBuffer(view: .init(count: capacity), values: lights.map(\.1), options: [])
        self.lightPositions = try device.makeBuffer(view: .init(count: capacity), values: lights.map(\.0), options: [])
    }
}

extension Lighting {
    func toArgumentBuffer() throws -> LightingArgumentBuffer {
        LightingArgumentBuffer(
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
