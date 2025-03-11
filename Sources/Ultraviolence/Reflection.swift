import Metal

public struct Reflection {
    public struct Key: Hashable {
        public var functionType: MTLFunctionType
        public var name: String
    }

    private var bindings: [Key: Int] = [:]

    public func binding(forType functionType: MTLFunctionType, name: String) -> Int? {
        bindings[.init(functionType: functionType, name: name)]
    }
}

extension Reflection {
    init(_ renderPipelineReflection: MTLRenderPipelineReflection) {
        for binding in renderPipelineReflection.fragmentBindings {
            bindings[.init(functionType: .fragment, name: binding.name)] = binding.index
        }
        for binding in renderPipelineReflection.vertexBindings {
            bindings[.init(functionType: .vertex, name: binding.name)] = binding.index
        }
    }
}

extension Reflection {
    init(_ computePipelineReflection: MTLComputePipelineReflection) {
        for binding in computePipelineReflection.bindings {
            bindings[.init(functionType: .kernel, name: binding.name)] = binding.index
        }
    }
}

extension Reflection: CustomDebugStringConvertible {
    public var debugDescription: String {
        bindings.debugDescription
    }
}

extension Reflection.Key: CustomDebugStringConvertible {
    public var debugDescription: String {
        "Key(type: .\(functionType) name: \"\(name)\")"
    }
}

extension MTLFunctionType: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .vertex:
            return "vertex"
        case .fragment:
            return "fragment"
        case .kernel:
            return "kernel"
        case .visible:
            return "visible"
        case .intersection:
            return "intersection"
        case .mesh:
            return "mesh"
        case .object:
            return "object"
        @unknown default:
            return "unknown"
        }
    }
}
