import Metal
import simd
internal import UltraviolenceSupport

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

// MARK: -

extension MTLRenderCommandEncoder {
    func setArgument(_ argument: Argument, reflection: MTLRenderPipelineReflection) throws {
        switch argument.functionType {
        // TODO: Logic for .fragment and .vertex are almost identical.
        case .fragment:
            guard let binding = reflection.fragmentBindings.first(where: { $0.name == argument.name }) else {
                throw UltraviolenceError.missingBinding(argument.name)
            }
            switch argument.value {
            case .float3, .float4, .matrix4x4:
                try withUnsafeBytes(of: argument.value) { buffer in
                    let baseAddress = try buffer.baseAddress.orThrow(.resourceCreationFailure)
                    setFragmentBytes(baseAddress, length: buffer.count, index: binding.index)
                }
            case .texture(let texture):
                setFragmentTexture(texture, index: binding.index)
            }
        case .vertex:
            guard let binding = reflection.vertexBindings.first(where: { $0.name == argument.name }) else {
                throw UltraviolenceError.missingBinding(argument.name)
            }
            switch argument.value {
            case .float3, .float4, .matrix4x4:
                try withUnsafeBytes(of: argument.value) { buffer in
                    let baseAddress = try buffer.baseAddress.orThrow(.resourceCreationFailure)
                    setVertexBytes(baseAddress, length: buffer.count, index: binding.index)
                }
            case .texture(let texture):
                setVertexTexture(texture, index: binding.index)
            }
        default:
            fatalError("Not implemented")
        }
    }
}

// MARK: -

extension MTLComputeCommandEncoder {
    func setArgument(_ argument: Argument, reflection: MTLComputePipelineReflection) throws {
        assert(argument.functionType == .kernel)
        let binding = try reflection.bindings.first { $0.name == argument.name }.orThrow(.missingBinding("\(argument.name)"))
        switch argument.value {
        case .float3, .float4, .matrix4x4:
            try withUnsafeBytes(of: argument.value) { buffer in
                guard let baseAddress = buffer.baseAddress else {
                    throw UltraviolenceError.resourceCreationFailure
                }
                setBytes(baseAddress, length: buffer.count, index: binding.index)
            }
        case .texture(let texture):
            setTexture(texture, index: binding.index)
        }
    }
}
