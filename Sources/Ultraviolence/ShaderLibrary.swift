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
        let device = MTLCreateSystemDefaultDevice().orFatalError()
        if let library = try? device.makeDefaultLibrary(bundle: bundle) {
            self.library = library
        }
        else {
            let url = try bundle.url(forResource: "debug", withExtension: "metallib").orThrow(.resourceCreationFailure)
            if let library = try? device.makeLibrary(URL: url) {
                self.library = library
            }
            else {
                throw UltraviolenceError.resourceCreationFailure
            }
        }
        self.namespace = namespace
    }

    internal func function(named name: String, type: MTLFunctionType) throws -> MTLFunction {
        let scopedNamed = namespace.map { "\($0)::\(name)" } ?? name
        guard let function = library.makeFunction(name: scopedNamed) else {
            throw UltraviolenceError.resourceCreationFailure
        }
        if function.functionType != type {
            throw UltraviolenceError.resourceCreationFailure
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
