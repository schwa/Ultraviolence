import Collections
import Foundation
import GeometryLite3D
import Metal

extension Mesh {
    init(_ trivial: TrivialMesh, device: MTLDevice) {
        self.label = trivial.label
        let vertexDescriptor = trivial.vertexDescriptor()
        self.vertexDescriptor = vertexDescriptor

        assert(vertexDescriptor.layouts.count == 1)

        // Get stride from vertex descriptor
        let vertexStride = vertexDescriptor.layouts[0].orFatalError("Invalid layout").stride

        // Create vertex buffer with interleaved data
        let vertexCount = trivial.positions.count
        var vertexData = [UInt8]()
        vertexData.reserveCapacity(vertexStride * vertexCount)

        for i in 0..<vertexCount {
            // Create a buffer for this vertex
            var vertexBytes = [UInt8](repeating: 0, count: vertexStride)

            // Write each attribute in the order defined by the vertex descriptor
            for attribute in vertexDescriptor.attributes.filter({ $0.bufferIndex == 0 }) {
                vertexBytes.withUnsafeMutableBytes { bytes in
                    let destination = bytes.baseAddress!.advanced(by: attribute.offset)

                    switch attribute.semantic {
                    case .position:
                        let position = Packed3<Float>(trivial.positions[i])
                        withUnsafeBytes(of: position) { source in
                            destination.copyMemory(from: source.baseAddress!, byteCount: source.count)
                        }
                    case .normal:
                        if let normals = trivial.normals {
                            let normal = Packed3<Float>(normals[i])
                            withUnsafeBytes(of: normal) { source in
                                destination.copyMemory(from: source.baseAddress!, byteCount: source.count)
                            }
                        }
                    case .texcoord:
                        if let texCoords = trivial.textureCoordinates {
                            let texCoord = texCoords[i]
                            withUnsafeBytes(of: texCoord) { source in
                                destination.copyMemory(from: source.baseAddress!, byteCount: source.count)
                            }
                        }
                    case .tangent:
                        if let tangents = trivial.tangents {
                            let tangent = Packed3<Float>(tangents[i])
                            withUnsafeBytes(of: tangent) { source in
                                destination.copyMemory(from: source.baseAddress!, byteCount: source.count)
                            }
                        }
                    case .bitangent:
                        if let bitangents = trivial.bitangents {
                            let bitangent = Packed3<Float>(bitangents[i])
                            withUnsafeBytes(of: bitangent) { source in
                                destination.copyMemory(from: source.baseAddress!, byteCount: source.count)
                            }
                        }
                    case .color:
                        if let colors = trivial.colors {
                            let color = colors[i]
                            withUnsafeBytes(of: color) { source in
                                destination.copyMemory(from: source.baseAddress!, byteCount: source.count)
                            }
                        }
                    case .unknown, .userDefined:
                        break
                    }
                }
            }

            vertexData.append(contentsOf: vertexBytes)
        }

        guard let vertexBuffer = device.makeBuffer(bytes: vertexData, length: vertexData.count, options: []) else {
            fatalError("Failed to create vertex buffer")
        }
        vertexBuffer.label = trivial.label.map { "\($0) Vertices" }

        self.vertexBuffers = [
            Buffer(buffer: vertexBuffer, count: vertexCount, offset: 0)
        ]

        // Create index buffer
        let indexData = trivial.indices.map { UInt32($0) }
        guard let indexBuffer = device.makeBuffer(bytes: indexData, length: MemoryLayout<UInt32>.stride * indexData.count, options: []) else {
            fatalError("Failed to create index buffer")
        }
        indexBuffer.label = trivial.label.map { "\($0) Indices" }

        self.submeshes = [
            Submesh(
                label: trivial.label,
                primitiveType: .triangle,
                indices: Buffer(buffer: indexBuffer, count: trivial.indices.count, offset: 0)
            )
        ]
    }
}

private extension Array<UInt8> {
    mutating func append<T>(bytesOf value: T) {
        Swift.withUnsafeBytes(of: value) { bytes in
            self.append(contentsOf: bytes)
        }
    }
}
