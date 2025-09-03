import Metal
import simd
import UltraviolenceExampleShaders

public enum Texture2DSpecifier {
    case texture(MTLTexture, MTLSamplerState)
    // TODO: #139 Switch to SIMD3<Float>??
    case color(SIMD3<Float>)
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

    var color: SIMD3<Float>? {
        if case let .color(color) = self {
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
        case .color(let color):
            result.source = .color
            result.color = color
        }
        return result
    }
}
