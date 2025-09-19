import Metal

public extension VertexShader {
    func inferredVertexDescriptor() throws -> MTLVertexDescriptor? {
        try function.inferredVertexDescriptor()
    }
}
