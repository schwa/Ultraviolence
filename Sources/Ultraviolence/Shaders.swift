import Metal
internal import UltraviolenceSupport

public struct VertexShader: RenderPass {
    public typealias Body = Never

    var function: MTLFunction

    public init(_ name: String) throws {
        let device = try MTLCreateSystemDefaultDevice().orThrow(.resourceCreationFailure)
        let library = try device.makeDefaultLibrary().orThrow(.resourceCreationFailure)
        function = try library.makeFunction(name: name).orThrow(.resourceCreationFailure)
    }

    public init(_ name: String, source: String) throws {
        let device = try MTLCreateSystemDefaultDevice().orThrow(.resourceCreationFailure)
        let library = try device.makeLibrary(source: source, options: nil)
        function = try library.makeFunction(name: name).orThrow(.resourceCreationFailure)
    }

    public func visit(_ visitor: inout Visitor) throws {
        visitor.log(label: "VertexShader.\(#function).") { visitor in
            visitor.insert(.function(function))
        }
    }
}

// MARK: -

public struct FragmentShader: RenderPass {
    public typealias Body = Never

    var function: MTLFunction

    public init(_ name: String) throws {
        let device = try MTLCreateSystemDefaultDevice().orThrow(.resourceCreationFailure)
        let library = try device.makeDefaultLibrary().orThrow(.resourceCreationFailure)
        function = try library.makeFunction(name: name).orThrow(.resourceCreationFailure)
    }

    public init(_ name: String, source: String) throws {
        let device = try MTLCreateSystemDefaultDevice().orThrow(.resourceCreationFailure)
        let library = try device.makeLibrary(source: source, options: nil)
        function = try library.makeFunction(name: name).orThrow(.resourceCreationFailure)
    }

    public func visit(_ visitor: inout Visitor) throws {
        visitor.log(label: "FragmentShader.\(#function).") { visitor in
            visitor.insert(.function(function))
        }
    }
}

// MARK: -

public struct ComputeShader: RenderPass {
    public typealias Body = Never

    var function: MTLFunction

    public init(_ name: String) throws {
        let device = try MTLCreateSystemDefaultDevice().orThrow(.resourceCreationFailure)
        let library = try device.makeDefaultLibrary().orThrow(.resourceCreationFailure)
        function = try library.makeFunction(name: name).orThrow(.resourceCreationFailure)
    }

    public init(_ name: String, source: String) throws {
        let device = try MTLCreateSystemDefaultDevice().orThrow(.resourceCreationFailure)
        let options = MTLCompileOptions()
        options.enableLogging = true
        let library = try device.makeLibrary(source: source, options: options)
        function = try library.makeFunction(name: name).orThrow(.resourceCreationFailure)
    }

    public func visit(_ visitor: inout Visitor) throws {
        visitor.log(label: "ComputeShader.\(#function).") { visitor in
            visitor.insert(.function(function))
        }
    }
}
