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
        let url = try bundle.url(forResource: "debug", withExtension: "metallib").orThrow(.resourceCreationFailure("Failed to find default library in bundle"))
        if let library = try? device.makeLibrary(URL: url) {
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

    internal func function(named name: String, type: MTLFunctionType) throws -> MTLFunction {
        let scopedNamed = namespace.map { "\($0)::\(name)" } ?? name
        guard let function = library.makeFunction(name: scopedNamed) else {
            throw UltraviolenceError.resourceCreationFailure("Function \(scopedNamed) not found.")
        }
        if function.functionType != type {
            throw UltraviolenceError.resourceCreationFailure("Function \(scopedNamed) is not of type \(type).")
        }
        return function
    }

    public subscript(dynamicMember name: String) -> ComputeKernel {
        get throws {
            let function = try function(named: name, type: .kernel)
            return ComputeKernel(function)
        }
    }

    public subscript(dynamicMember name: String) -> VertexShader {
        get throws {
            let function = try function(named: name, type: .vertex)
            return VertexShader(function)
        }
    }

    public subscript(dynamicMember name: String) -> FragmentShader {
        get throws {
            let function = try function(named: name, type: .fragment)
            return FragmentShader(function)
        }
    }
}
