import Metal

public protocol Example {
    @MainActor
    static func runExample() throws -> ExampleResult
}

public enum ExampleResult {
    case nothing
    case texture(MTLTexture)
}
