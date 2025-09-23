import Metal
import simd
import Ultraviolence
import UltraviolenceExampleShaders

public enum ColorSpecifier {
    case texture2D(MTLTexture, MTLSamplerState?)
    case textureCube(MTLTexture, MTLSamplerState?, Int)
    case depth2D(MTLTexture, MTLSamplerState?)
    case color(SIMD3<Float>)

    static func texture2D(_ texture: MTLTexture) -> Self {
        .texture2D(texture, nil)
    }
}

public extension ColorSpecifier {
    var texture2D: MTLTexture? {
        if case let .texture2D(texture, _) = self {
            // TODO: #287 Assert value is correct.
            return texture
        }
        return nil
    }

    var textureCube: MTLTexture? {
        if case let .textureCube(texture, _, _) = self {
            // TODO: #287 Assert value is correct.
            return texture
        }
        return nil
    }

    var depth2D: MTLTexture? {
        if case let .depth2D(texture, _) = self {
            // TODO: #287 Assert value is correct.
            return texture
        }
        return nil
    }

    var sampler: MTLSamplerState? {
        switch self {
        case let .texture2D(_, sampler), let .textureCube(_, sampler, _), let .depth2D(_, sampler):
            return sampler
        default:
            return nil
        }
    }

    var slice: Int? {
        if case let .textureCube(_, _, slice) = self {
            return slice
        }
        return nil
    }

    var color: SIMD3<Float>? {
        if case let .color(color) = self {
            return color
        }
        return nil
    }
}

public extension ColorSpecifier {
    // TODO: We may want some kind of `argumentBufferRepresentable` protocol. Should also support `useResource` [FILE ME]
    func toArgumentBuffer() -> ColorSpecifierArgumentBuffer {
        var result = ColorSpecifierArgumentBuffer()
        switch self {
        case .texture2D(let texture, let sampler):
            result.source = .texture2D
            result.texture2D = texture.gpuResourceID
            result.sampler = sampler.map(\.gpuResourceID) ?? .init()
        case .textureCube(let texture, let sampler, let slice):
            result.source = .textureCube
            result.textureCube = texture.gpuResourceID
            result.sampler = sampler.map(\.gpuResourceID) ?? .init()
            result.slice = UInt32(slice)
        case .depth2D(let texture, let sampler):
            result.source = .depth2D
            result.depth2D = texture.gpuResourceID
            result.sampler = sampler.map(\.gpuResourceID) ?? .init()
        case .color(let color):
            result.source = .color
            result.color = color
        }
        return result
    }
}

extension Element {
    func useResource(_ colorSpecifier: ColorSpecifier, usage: MTLResourceUsage, stages: MTLRenderStages) -> some Element {
        self
            .useResource(colorSpecifier.texture2D, usage: usage, stages: stages)
            .useResource(colorSpecifier.textureCube, usage: usage, stages: stages)
        // TODO: This causes a hang. [FILE ME]
//            .useResource(colorSpecifier.depth2D, usage: usage, stages: stages)
    }

}

