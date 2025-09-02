import Metal
import UltraviolenceSupport

@dynamicMemberLookup
public struct ShaderLibrary {
    var library: MTLLibrary
    var namespace: String?

    public init(library: MTLLibrary, namespace: String? = nil) {
        self.library = library
        self.namespace = namespace
    }

    public init(bundle: Bundle, namespace: String? = nil) throws {
        let device = _MTLCreateSystemDefaultDevice()

        if let url = bundle.url(forResource: "debug", withExtension: "metallib"), let library = try? device.makeLibrary(URL: url) {
            self.library = library
        }
        else {
            if let library = try? device.makeDefaultLibrary(bundle: bundle) {
                self.library = library
            }
            else {
                throw UltraviolenceError.resourceCreationFailure("Failed to load default library from bundle.")
            }
        }
        self.namespace = namespace
    }

    @available(*, deprecated, message: "Use the type-safe function<T>(named:type:constantValues:) method instead")
    internal func function(named name: String, type: MTLFunctionType? = nil, constantValues: MTLFunctionConstantValues? = nil) throws -> MTLFunction {
        let scopedNamed = namespace.map { "\($0)::\(name)" } ?? name
        let constantValues = constantValues ?? MTLFunctionConstantValues()
        let function = try library.makeFunction(name: scopedNamed, constantValues: constantValues)
        if let type, function.functionType != type {
            throw UltraviolenceError.resourceCreationFailure("Function \(scopedNamed) is not of type \(type).")
        }
        return function
    }

    public func function<T>(named name: String, type: T.Type, constantValues: MTLFunctionConstantValues? = nil) throws -> T where T: ShaderProtocol {
        let scopedNamed = namespace.map { "\($0)::\(name)" } ?? name
        let constantValues = constantValues ?? MTLFunctionConstantValues()
        let function = try library.makeFunction(name: scopedNamed, constantValues: constantValues)
        switch type {
        // TODO: #94 Clean this up.
        case is VertexShader.Type:
            guard function.functionType == .vertex else {
                throw UltraviolenceError.resourceCreationFailure("Function \(scopedNamed) is not a vertex function.")
            }
            return (VertexShader(function) as? T).orFatalError(.resourceCreationFailure("Failed to create VertexShader."))
        case is FragmentShader.Type:
            guard function.functionType == .fragment else {
                throw UltraviolenceError.resourceCreationFailure("Function \(scopedNamed) is not a fragment function.")
            }
            return (FragmentShader(function) as? T).orFatalError(.resourceCreationFailure("Failed to create FragmentShader."))
        case is ComputeKernel.Type:
            guard function.functionType == .kernel else {
                throw UltraviolenceError.resourceCreationFailure("Function \(scopedNamed) is not a kernel function.")
            }
            return (ComputeKernel(function) as? T).orFatalError(.resourceCreationFailure("Failed to create ComputeKernel."))
        default:
            throw UltraviolenceError.resourceCreationFailure("Unknown shader type \(type).")
        }
    }
}

public extension ShaderLibrary {
    subscript(dynamicMember name: String) -> ComputeKernel {
        get throws {
            try function(named: name, type: ComputeKernel.self)
        }
    }

    subscript(dynamicMember name: String) -> VertexShader {
        get throws {
            try function(named: name, type: VertexShader.self)
        }
    }

    subscript(dynamicMember name: String) -> FragmentShader {
        get throws {
            try function(named: name, type: FragmentShader.self)
        }
    }
}
