import Metal

public struct VertexShader {
    let function: MTLFunction

    public init(source: String) throws {
        let device = try MTLCreateSystemDefaultDevice().orThrow(.resourceCreationFailure)
        let library = try device.makeLibrary(source: source, options: nil)
        function = try library.functionNames.compactMap { library.makeFunction(name: $0) }.first { $0.functionType == .vertex }.orThrow(.resourceCreationFailure)
    }
}

public struct FragmentShader {
    let function: MTLFunction

    public init(source: String) throws {
        let device = try MTLCreateSystemDefaultDevice().orThrow(.resourceCreationFailure)
        let library = try device.makeLibrary(source: source, options: nil)
        function = try library.functionNames.compactMap { library.makeFunction(name: $0) }.first { $0.functionType == .fragment }.orThrow(.resourceCreationFailure)
    }
}

public extension VertexShader {
    var vertexDescriptor: MTLVertexDescriptor? {
        function.vertexDescriptor
    }
}
