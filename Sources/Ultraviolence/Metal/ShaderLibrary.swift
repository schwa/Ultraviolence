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
                try _throw(UltraviolenceError.resourceCreationFailure("Failed to load default library from bundle."))
            }
        }
        self.namespace = namespace
    }

    public func function<T>(named name: String, type: T.Type, constants: FunctionConstants = FunctionConstants()) throws -> T where T: ShaderProtocol {

        logger?.verbose?.log("Loading function '\(name)' from library \(library.label ?? "<unnamed>")")


        let scopedNamed = namespace.map { "\($0)::\(name)" } ?? name

        let function: MTLFunction

        if !constants.isEmpty {
            // Build the constant values using the unspecialized function for introspection
            let mtlConstants = try constants.buildMTLConstants(for: library, functionName: scopedNamed)

            // Now create the SPECIALIZED function with the constants applied
            function = try library.makeFunction(name: scopedNamed, constantValues: mtlConstants)
        } else {
            // No constants, just get the function directly
            guard let basicFunction = library.makeFunction(name: scopedNamed) else {
                try _throw(UltraviolenceError.resourceCreationFailure("Function '\(scopedNamed)' not found in library (available: \(library.functionNames))."))
            }
            function = basicFunction
        }
        switch type {
        // TODO: #94 Clean this up.
        case is VertexShader.Type:
            guard function.functionType == .vertex else {
                try _throw(UltraviolenceError.resourceCreationFailure("Function \(scopedNamed) is not a vertex function."))
            }
            return (VertexShader(function) as? T).orFatalError(.resourceCreationFailure("Failed to create VertexShader."))
        case is FragmentShader.Type:
            guard function.functionType == .fragment else {
                try _throw(UltraviolenceError.resourceCreationFailure("Function \(scopedNamed) is not a fragment function."))
            }
            return (FragmentShader(function) as? T).orFatalError(.resourceCreationFailure("Failed to create FragmentShader."))
        case is ComputeKernel.Type:
            guard function.functionType == .kernel else {
                try _throw(UltraviolenceError.resourceCreationFailure("Function \(scopedNamed) is not a kernel function."))
            }
            return (ComputeKernel(function) as? T).orFatalError(.resourceCreationFailure("Failed to create ComputeKernel."))

        case is VisibleFunction.Type:
            guard function.functionType == .visible else {
                try _throw(UltraviolenceError.resourceCreationFailure("Function \(scopedNamed) is not a visible function."))
            }
            return (VisibleFunction(function) as? T).orFatalError(.resourceCreationFailure("Failed to create ComputeKernel."))
        default:
            try _throw(UltraviolenceError.resourceCreationFailure("Unknown shader type \(type)."))
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
