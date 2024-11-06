import MetalKit
import simd

// TOOD: Placeholder.
public protocol Geometry {
    func mesh() throws -> Mesh
}

// TOOD: Placeholder.
public enum Mesh {
    case simple(SimpleMesh)
    case mtkMesh(MTKMesh)
}

public extension Mesh {
    var vertexDescriptor: MTLVertexDescriptor {
        switch self {
        case let .simple(simpleMesh):
            return simpleMesh.vertexDescriptor
        case let .mtkMesh(mtkMesh):
            fatalError("Unimplemented")
        }
    }
}

// MARK: -

public struct Quad2D {
    public var origin: SIMD2<Float> = .zero
    public var size: SIMD2<Float> = .one

    public init(origin: SIMD2<Float>, size: SIMD2<Float>) {
        self.origin = origin
        self.size = size
    }
}

extension Quad2D: Geometry {
    public func mesh() throws -> Mesh {
        let positions = vertices(for: .triangle)
        let textureCoordinates = Quad2D(origin: [0, 0], size: [1, 1]).vertices(for: .triangle).map { SIMD2<Float>($0.x, $0.y) }
        return .simple(SimpleMesh(positions: positions, textureCoordinates: textureCoordinates))
    }

    func vertices(for primitive: MTLPrimitiveType) -> [SIMD3<Float>] {
        switch primitive {
        case .triangle:
            return [
                // Two triangles (six vertices) forming a quad.
                [origin.x, origin.y, 0],
                [origin.x + size.x, origin.y, 0],
                [origin.x, origin.y + size.y, 0],
                [origin.x + size.x, origin.y, 0],
                [origin.x + size.x, origin.y + size.y, 0],
                [origin.x, origin.y + size.y, 0]
            ]
        default:
            fatalError("Not implemented")
        }
    }
}

public struct SimpleMesh {
    public var positions: [SIMD3<Float>]
    // swiftlint:disable:next discouraged_optional_collection
    public var normals: [SIMD3<Float>]?
    // swiftlint:disable:next discouraged_optional_collection
    public var textureCoordinates: [SIMD2<Float>]?
    // swiftlint:disable:next discouraged_optional_collection
    public var indices: [UInt16]?
}

public extension SimpleMesh {
    var vertexDescriptor: MTLVertexDescriptor {
        let vertexDescriptor = MTLVertexDescriptor()
        var index = 0
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].bufferIndex = index
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<SIMD3<Float>>.size
        index += 1
        if normals != nil {
            vertexDescriptor.attributes[index].format = .float3
            vertexDescriptor.attributes[index].bufferIndex = index
            vertexDescriptor.attributes[index].offset = 0
            vertexDescriptor.layouts[index].stride = MemoryLayout<SIMD3<Float>>.size
            index += 1
        }
        if textureCoordinates != nil {
            vertexDescriptor.attributes[index].format = .float2
            vertexDescriptor.attributes[index].bufferIndex = index
            vertexDescriptor.attributes[index].offset = 0
            vertexDescriptor.layouts[index].stride = MemoryLayout<SIMD2<Float>>.size
            index += 1
        }
        return vertexDescriptor
    }
}

extension MTLRenderCommandEncoder {
    func draw(simpleMesh: SimpleMesh) throws {
        var bufferIndex = 0
        try simpleMesh.positions.withUnsafeBytes { buffer in
            let baseAddress = try buffer.baseAddress.orThrow(.resourceCreationFailure)
            self.setVertexBytes(baseAddress, length: buffer.count, index: bufferIndex)
            bufferIndex += 1
        }
        if let normals = simpleMesh.normals {
            assert(normals.count == simpleMesh.positions.count)
            try normals.withUnsafeBytes { buffer in
                let baseAddress = try buffer.baseAddress.orThrow(.resourceCreationFailure)
                self.setVertexBytes(baseAddress, length: buffer.count, index: bufferIndex)
            }
            bufferIndex += 1
        }
        if let textureCoordinates = simpleMesh.textureCoordinates {
            assert(textureCoordinates.count == simpleMesh.positions.count)
            try textureCoordinates.withUnsafeBytes { buffer in
                let baseAddress = try buffer.baseAddress.orThrow(.resourceCreationFailure)
                self.setVertexBytes(baseAddress, length: buffer.count, index: bufferIndex)
            }
            bufferIndex += 1
        }
        if let indices = simpleMesh.indices {
            // TODO: We can only draw with indices if indices is in a MTLBuffer already I think.
            fatalError("Unimplemented.")
        }
        else {
            self.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: simpleMesh.positions.count)
        }
    }
}

extension Mesh {
    func draw(encoder: MTLRenderCommandEncoder) throws {
        switch self {
        case .simple(let simpleMesh):

            try encoder.draw(simpleMesh: simpleMesh)
        case .mtkMesh(let mtkMesh):
            // TODO: Verify vertex shader vertex descriptor matches mesh vertex descriptor.
            for submesh in mtkMesh.submeshes {
                for (index, vertexBuffer) in mtkMesh.vertexBuffers.enumerated() {
                    encoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: index)
                }
                encoder.drawIndexedPrimitives(type: submesh.primitiveType, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer.buffer, indexBufferOffset: submesh.indexBuffer.offset)
            }
        }
    }
}
