import Metal
import UltraviolenceSupport

public protocol ShaderProtocol {
    static var functionType: MTLFunctionType { get }
    var function: MTLFunction { get }
    init(_ function: MTLFunction)
}

internal extension ShaderProtocol {
    init(library: MTLLibrary? = nil, namespace: String? = nil, name: String) throws {
        let library = try library ?? MTLCreateSystemDefaultDevice().orThrow(.resourceCreationFailure).makeDefaultLibrary().orThrow(.resourceCreationFailure)
        let scopedName = namespace.map { $0 + "::" + name } ?? name
        let function = try library.makeFunction(name: scopedName).orThrow(.resourceCreationFailure)
        if function.functionType != Self.functionType {
            throw UltraviolenceError.resourceCreationFailure
        }
        self.init(function)
    }
}

public extension ShaderProtocol {
    init(source: String, logging: Bool = false) throws {
        let device = try MTLCreateSystemDefaultDevice().orThrow(.resourceCreationFailure)
        let options = MTLCompileOptions()
        options.enableLogging = logging
        let library = try device.makeLibrary(source: source, options: options)
        let function = try library.functionNames.compactMap { library.makeFunction(name: $0) }.first { $0.functionType == Self.functionType }.orThrow(.resourceCreationFailure)
        self.init(function)
    }

    init(library: MTLLibrary? = nil, name: String) throws {
        let library = try library ?? MTLCreateSystemDefaultDevice().orThrow(.resourceCreationFailure).makeDefaultLibrary().orThrow(.resourceCreationFailure)
        let function = try library.makeFunction(name: name).orThrow(.resourceCreationFailure)
        if function.functionType != .kernel {
            throw UltraviolenceError.resourceCreationFailure
        }
        self.init(function)
    }
}

// MARK: -

public struct ComputeKernel: ShaderProtocol {
    public static let functionType: MTLFunctionType = .kernel
    public var function: MTLFunction

    public init(_ function: MTLFunction) {
        self.function = function
    }
}

// MARK: -

public struct VertexShader: ShaderProtocol {
    public static let functionType: MTLFunctionType = .vertex
    public var function: MTLFunction

    public init(_ function: MTLFunction) {
        self.function = function
    }
}

public extension VertexShader {
    var vertexDescriptor: MTLVertexDescriptor? {
        function.vertexDescriptor
    }
}

// MARK: -

public struct FragmentShader: ShaderProtocol {
    public static let functionType: MTLFunctionType = .fragment
    public var function: MTLFunction

    public init(_ function: MTLFunction) {
        self.function = function
    }
}
