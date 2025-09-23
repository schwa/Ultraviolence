import simd
import GeometryLite3D
import Metal
import UltraviolenceSupport

struct Mesh {
    var label: String?
    var submeshes: [Submesh]
    var vertexDescriptor: VertexDescriptor
    var vertexBuffers: [Buffer]

    struct Submesh {
        var label: String?
        var primitiveType: MTLPrimitiveType
        var indices: Buffer
    }

    struct Buffer {
        var buffer: MTLBuffer
        var count: Int
        var offset: Int
    }

    init(label: String? = nil, submeshes: [Submesh], vertexDescriptor: VertexDescriptor, vertexBuffers: [Buffer]) {
        self.label = label
        self.submeshes = submeshes
        self.vertexDescriptor = vertexDescriptor
        self.vertexBuffers = vertexBuffers
    }
}

extension MTLRenderCommandEncoder {
    func draw(mesh: Mesh) {
        // TODO: Simple case
        assert(mesh.vertexBuffers.count == 1)
        setVertexBuffer(mesh.vertexBuffers[0].buffer, offset: mesh.vertexBuffers[0].offset, index: 0) // TODO: Index
        for submesh in mesh.submeshes {
            drawIndexedPrimitives(type: submesh.primitiveType, indexCount: submesh.indices.count, indexType: .uint32, indexBuffer: submesh.indices.buffer, indexBufferOffset: submesh.indices.offset)
        }
    }
}
