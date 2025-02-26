import Metal

public protocol Example {
    @MainActor
    static func runExample() throws -> ExampleResult
}

@MainActor
var allExamples: [Example.Type] = [
    CheckerboardKernel.self
]

public enum ExampleResult {
    case nothing
    case texture(MTLTexture)
}
