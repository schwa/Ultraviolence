import Metal
import UltraviolenceSupport

public protocol ShaderProtocol {
    static var functionType: MTLFunctionType { get }
    var function: MTLFunction { get }
    init(_ function: MTLFunction)
}

public extension ShaderProtocol {
    init(source: String, logging: Bool = false) throws {
        let device = _MTLCreateSystemDefaultDevice()
        let options = MTLCompileOptions()
        options.enableLogging = logging
        let library = try device.makeLibrary(source: source, options: options)
        let function = try library.functionNames.compactMap { library.makeFunction(name: $0) }.first { $0.functionType == Self.functionType }.orThrow(.resourceCreationFailure("Failed to create function"))
        self.init(function)
    }

    init(library: MTLLibrary? = nil, name: String) throws {
        let library = try library ?? _MTLCreateSystemDefaultDevice().makeDefaultLibrary().orThrow(.resourceCreationFailure("Failed to create default library"))
        let function = try library.makeFunction(name: name).orThrow(.resourceCreationFailure("Failed to create function"))
        if function.functionType != .kernel {
            throw UltraviolenceError.resourceCreationFailure("Function type is not kernel")
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
    func inferredVertexDescriptor() -> MTLVertexDescriptor? {
        function.inferredVertexDescriptor()
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
