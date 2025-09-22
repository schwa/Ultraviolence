import Metal
import Ultraviolence
import UltraviolenceExampleShaders
import UltraviolenceSupport

public typealias BlinnPhongLight = UltraviolenceExampleShaders.BlinnPhongLight

public struct BlinnPhongMaterial {
    public enum ColorSource {
        case color(SIMD3<Float>)
        case texture(MTLTexture, MTLSamplerState)

        var texture: MTLTexture? {
            if case let .texture(texture, _) = self {
                return texture
            }
            return nil
        }
    }
    public var ambient: ColorSource
    public var diffuse: ColorSource
    public var specular: ColorSource
    public var shininess: Float

    public init(ambient: ColorSource, diffuse: ColorSource, specular: ColorSource, shininess: Float) {
        self.ambient = ambient
        self.diffuse = diffuse
        self.specular = specular
        self.shininess = shininess
    }
}

extension BlinnPhongMaterial {
    func toArgumentBuffer() throws -> BlinnPhongMaterialArgumentBuffer {
        var result = BlinnPhongMaterialArgumentBuffer()
        switch ambient {
        case .color(let color):
            result.ambientSource = UltraviolenceExampleShaders.ColorSource.color
            result.ambientColor = color
        case .texture(let texture, let sampler):
            result.ambientSource = UltraviolenceExampleShaders.ColorSource.texture2D
            result.ambientTexture = texture.gpuResourceID
            result.ambientSampler = sampler.gpuResourceID
        }
        switch diffuse {
        case .color(let color):
            result.diffuseSource = UltraviolenceExampleShaders.ColorSource.color
            result.diffuseColor = color
        case .texture(let texture, let sampler):
            result.diffuseSource = UltraviolenceExampleShaders.ColorSource.texture2D
            result.diffuseTexture = texture.gpuResourceID
            result.diffuseSampler = sampler.gpuResourceID
        }
        switch specular {
        case .color(let color):
            result.specularSource = UltraviolenceExampleShaders.ColorSource.color
            result.specularColor = color
        case .texture(let texture, let sampler):
            result.specularSource = UltraviolenceExampleShaders.ColorSource.texture2D
            result.specularTexture = texture.gpuResourceID
            result.specularSampler = sampler.gpuResourceID
        }
        result.shininess = shininess
        return result
    }
}

struct BlinnPhongLighting {
    var ambientLightColor: simd_float3
    var count: Int
    var lights: MTLBuffer
    var lightPositions: MTLBuffer
}

extension BlinnPhongLighting {
    func toArgumentBuffer() throws -> BlinnPhongLightingModelArgumentBuffer {
        return BlinnPhongLightingModelArgumentBuffer(
            lightCount: Int32(count),
            ambientLightColor: ambientLightColor,
            lights: lights.gpuAddressAsUnsafeMutablePointer(type: BlinnPhongLight.self).orFatalError(),
            lightPositions: lightPositions.gpuAddressAsUnsafeMutablePointer(type: SIMD3<Float>.self).orFatalError()
        )
    }
}

extension Element {
    func blinnPhongMaterial(_ material: BlinnPhongMaterial) throws -> some Element {
        self
            .parameter("material", value: try material.toArgumentBuffer())
            .useResource(material.ambient.texture, usage: .read, stages: .fragment)
            .useResource(material.diffuse.texture, usage: .read, stages: .fragment)
            .useResource(material.specular.texture, usage: .read, stages: .fragment)
    }

    func blinnPhongLighting(_ lighting: BlinnPhongLighting) throws -> some Element {
        self
            .parameter("lighting", value: try lighting.toArgumentBuffer())
            .useResource(lighting.lights, usage: .read, stages: .fragment)
            .useResource(lighting.lightPositions, usage: .read, stages: .fragment)
    }
}
