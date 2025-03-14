import Metal
import simd
import UltraviolenceExampleShaders

public enum Texture2DSpecifier {
    case texture(MTLTexture, MTLSamplerState)
    // TODO: #139 Just color - and switch to SIMD3<Float>??
    case solidColor(SIMD4<Float>)
}

public extension Texture2DSpecifier {
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

    var solidColor: SIMD4<Float>? {
        if case let .solidColor(color) = self {
            return color
        }
        return nil
    }
}

public extension Texture2DSpecifier {
    func toTexture2DSpecifierArgmentBuffer() -> Texture2DSpecifierArgumentBuffer {
        var result = Texture2DSpecifierArgumentBuffer()
        switch self {
        case .texture(let texture, let sampler):
            result.source = .texture
            result.texture = texture.gpuResourceID
            result.sampler = sampler.gpuResourceID
        case .solidColor(let color):
            result.source = .color
            result.color = color
        }
        return result
    }
}
