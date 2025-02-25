import Metal

public protocol Example {
    @MainActor
    static func runExample() throws -> MTLTexture
}


@MainActor
var allExamples: [Example.Type] = [
    CheckerboardKernel.self
]
