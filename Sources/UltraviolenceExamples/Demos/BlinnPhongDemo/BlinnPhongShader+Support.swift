import Metal
import Ultraviolence
import UltraviolenceExampleShaders
import UltraviolenceSupport

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


extension Element {
    func blinnPhongMaterial(_ material: BlinnPhongMaterial) throws -> some Element {
        self
            .parameter("material", value: try material.toArgumentBuffer())
            .useResource(material.ambient.texture, usage: .read, stages: .fragment)
            .useResource(material.diffuse.texture, usage: .read, stages: .fragment)
            .useResource(material.specular.texture, usage: .read, stages: .fragment)
    }
}
