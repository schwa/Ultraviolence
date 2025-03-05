import Metal
import Ultraviolence
import UltraviolenceExampleShaders
import UltraviolenceSupport

public typealias Transforms = UltraviolenceExampleShaders.Transforms
public typealias BlinnPhongLight = UltraviolenceExampleShaders.BlinnPhongLight

public extension Transforms {
    init(modelMatrix: simd_float4x4, cameraMatrix: simd_float4x4, projectionMatrix: simd_float4x4) {
        self.init()

        self.cameraMatrix = cameraMatrix
        self.modelMatrix = modelMatrix
        self.viewMatrix = cameraMatrix.inverse
        self.projectionMatrix = projectionMatrix
        self.modelViewMatrix = viewMatrix * modelMatrix

        self.modelViewProjectionMatrix = projectionMatrix * viewMatrix * modelMatrix
        self.modelNormalMatrix = modelMatrix.upperLeft
    }
}

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

        var sampler: MTLSamplerState? {
            if case let .texture(_, sampler) = self {
                return sampler
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
            result.ambientSource = UltraviolenceExampleShaders.ColorSource.texture
            result.ambientTexture = texture.gpuResourceID
            result.ambientSampler = sampler.gpuResourceID
        }
        switch diffuse {
        case .color(let color):
            result.diffuseSource = UltraviolenceExampleShaders.ColorSource.color
            result.diffuseColor = color
        case .texture(let texture, let sampler):
            result.diffuseSource = UltraviolenceExampleShaders.ColorSource.texture
            result.diffuseTexture = texture.gpuResourceID
            result.diffuseSampler = sampler.gpuResourceID
        }
        switch specular {
        case .color(let color):
            result.specularSource = UltraviolenceExampleShaders.ColorSource.color
            result.specularColor = color
        case .texture(let texture, let sampler):
            result.specularSource = UltraviolenceExampleShaders.ColorSource.texture
            result.specularTexture = texture.gpuResourceID
            result.specularSampler = sampler.gpuResourceID
        }
        result.shininess = shininess
        return result
    }
}

public struct BlinnPhongLighting {
    public var screenGamma: Float
    public var ambientLightColor: simd_float3
    public var lights: TypedMTLBuffer<BlinnPhongLight>

    public init(screenGamma: Float, ambientLightColor: simd_float3, lights: TypedMTLBuffer<BlinnPhongLight>) {
        self.screenGamma = screenGamma
        self.ambientLightColor = ambientLightColor
        self.lights = lights
    }
}

extension BlinnPhongLighting {
    func toArgumentBuffer() throws -> BlinnPhongLightingModelArgumentBuffer {
        BlinnPhongLightingModelArgumentBuffer(
            screenGamma: screenGamma,
            lightCount: Int32(lights.count),
            ambientLightColor: ambientLightColor,
            lights: lights.unsafeMTLBuffer.gpuAddressAsUnsafeMutablePointer(type: BlinnPhongLight.self).orFatalError()
        )
    }
}

public extension Element {
    func blinnPhongMaterial(_ material: BlinnPhongMaterial) throws -> some Element {
        self
            .parameter("material", value: try material.toArgumentBuffer())
            .useResource(material.ambient.texture, usage: .read, stages: .fragment)
            .useResource(material.diffuse.texture, usage: .read, stages: .fragment)
            .useResource(material.specular.texture, usage: .read, stages: .fragment)
    }

    func blinnPhongLighting(_ lighting: BlinnPhongLighting) throws -> some Element {
        self
            .parameter("lightingModel", value: try lighting.toArgumentBuffer())
            .useResource(lighting.lights.unsafeMTLBuffer, usage: .read, stages: .fragment)
    }
    func blinnPhongTransforms(_ transforms: Transforms) throws -> some Element {
        self
            .parameter("transforms", value: transforms, functionType: .vertex)
            .parameter("transforms_f", value: transforms, functionType: .fragment)
    }
}
