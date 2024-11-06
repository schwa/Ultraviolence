import Metal
import simd

public struct Argument {
    public var functionType: MTLFunctionType
    public var name: String
    public var binding: Int = -1
    public var value: Value
}

public enum Value {
    case float3(SIMD3<Float>)
    case float4(SIMD4<Float>)
    case matrix4x4(simd_float4x4)
    case texture(MTLTexture)
}

public extension RenderPass {
    func argument(type: MTLFunctionType, name: String, value: Value) -> some RenderPass {
        let argument = Argument(functionType: type, name: name, value: value)
        return EnvironmentRenderPass(environment: [.arguments([argument])]) {
            self
        }
    }

    func argument(type: MTLFunctionType, name: String, value: SIMD4<Float>) -> some RenderPass {
        argument(type: type, name: name, value: .float4(value))
    }

    func argument(type: MTLFunctionType, name: String, value: SIMD3<Float>) -> some RenderPass {
        argument(type: type, name: name, value: .float3(value))
    }

    func argument(type: MTLFunctionType, name: String, value: simd_float4x4) -> some RenderPass {
        argument(type: type, name: name, value: .matrix4x4(value))
    }

    func argument(type: MTLFunctionType, name: String, value: MTLTexture) -> some RenderPass {
        argument(type: type, name: name, value: .texture(value))
    }
}
