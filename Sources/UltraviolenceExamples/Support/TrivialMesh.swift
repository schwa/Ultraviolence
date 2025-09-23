import simd
import Metal
import Collections

struct TrivialMesh: Equatable, Sendable {
    var label: String?
    var indices: [Int]
    var positions: [SIMD3<Float>]
    var textureCoordinates: [SIMD2<Float>]?
    var normals: [SIMD3<Float>]?
    var tangents: [SIMD3<Float>]?
    var bitangents: [SIMD3<Float>]?
    var colors: [SIMD4<Float>]?
}

extension TrivialMesh {
    func scaled(_ scale: SIMD3<Float>) -> TrivialMesh {
        var result = self
        result.positions = positions.map { $0 * scale }
        if let normals = normals {
            let inverseScale = SIMD3<Float>(1.0 / scale.x, 1.0 / scale.y, 1.0 / scale.z)
            result.normals = normals.map { normalize($0 * inverseScale) }
        }
        if let tangents = tangents {
            let inverseScale = SIMD3<Float>(1.0 / scale.x, 1.0 / scale.y, 1.0 / scale.z)
            result.tangents = tangents.map { normalize($0 * inverseScale) }
        }
        if let bitangents = bitangents {
            let inverseScale = SIMD3<Float>(1.0 / scale.x, 1.0 / scale.y, 1.0 / scale.z)
            result.bitangents = bitangents.map { normalize($0 * inverseScale) }
        }
        return result
    }

    func translated(_ translation: SIMD3<Float>) -> TrivialMesh {
        var result = self
        result.positions = positions.map { $0 + translation }
        return result
    }

    func rotated(_ rotation: simd_quatf) -> TrivialMesh {
        var result = self
        let rotationMatrix = float3x3(rotation)
        result.positions = positions.map { rotationMatrix * $0 }
        if let normals = normals {
            result.normals = normals.map { rotationMatrix * $0 }
        }
        if let tangents = tangents {
            result.tangents = tangents.map { rotationMatrix * $0 }
        }
        if let bitangents = bitangents {
            result.bitangents = bitangents.map { rotationMatrix * $0 }
        }
        return result
    }
}

extension TrivialMesh {
    func vertexDescriptor() -> VertexDescriptor {
        // Create vertex descriptor
        var attributes: [VertexDescriptor.Attribute] = [
            // Position attribute (always present)
            .init(semantic: .position, format: .float3, offset: 0, bufferIndex: 0)
        ]

        // Normal attribute (optional)
        if normals != nil {
            attributes.append(VertexDescriptor.Attribute(semantic: .normal, format: .float3, offset: 0, bufferIndex: 0 ))
        }

        // Texture coordinate attribute (optional)
        if textureCoordinates != nil {
            attributes.append(VertexDescriptor.Attribute(semantic: .texcoord, format: .float2, offset: 0, bufferIndex: 0 ))
        }

        if tangents != nil {
            attributes.append(VertexDescriptor.Attribute(semantic: .tangent, format: .float3, offset: 0, bufferIndex: 0 ))
        }

        // Color attribute (optional)
        if colors != nil {
            attributes.append(VertexDescriptor.Attribute(semantic: .color, format: .float4, offset: 0, bufferIndex: 0))
        }

        let result = VertexDescriptor(
            attributes: attributes,
            layouts: [.init(bufferIndex: 0, stride: 0, stepFunction: .perVertex, stepRate: 1)]
        )
        .normalized()
        return result
    }
}
