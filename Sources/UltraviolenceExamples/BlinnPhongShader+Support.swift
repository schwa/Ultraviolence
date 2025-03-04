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
            result.ambientSource = .init(rawValue: 0)
            result.ambientColor = color
        case .texture(let texture, let sampler):
            result.ambientSource = .init(rawValue: 1)
            result.ambientTexture = texture.gpuResourceID
            result.ambientSampler = sampler.gpuResourceID
        }
        switch diffuse {
        case .color(let color):
            result.diffuseSource = .init(rawValue: 0)
            result.diffuseColor = color
        case .texture(let texture, let sampler):
            result.diffuseSource = .init(rawValue: 1)
            result.diffuseTexture = texture.gpuResourceID
            result.diffuseSampler = sampler.gpuResourceID
        }
        switch specular {
        case .color(let color):
            result.specularSource = .init(rawValue: 0)
            result.specularColor = color
        case .texture(let texture, let sampler):
            result.specularSource = .init(rawValue: 1)
            result.specularTexture = texture.gpuResourceID
            result.specularSampler = sampler.gpuResourceID
        }
        result.shininess = shininess
        return result
    }

    func useResource(on renderCommandEncoder: MTLRenderCommandEncoder) {
        if case let .texture(texture, _) = ambient {
            renderCommandEncoder.useResource(texture, usage: .read, stages: .fragment)
        }
        if case let .texture(texture, _) = diffuse {
            renderCommandEncoder.useResource(texture, usage: .read, stages: .fragment)
        }
        if case let .texture(texture, _) = specular {
            renderCommandEncoder.useResource(texture, usage: .read, stages: .fragment)
        }
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

    func useResource(on renderCommandEncoder: MTLRenderCommandEncoder) {
        renderCommandEncoder.useResource(lights.unsafeMTLBuffer, usage: .read, stages: .fragment)
    }
}
