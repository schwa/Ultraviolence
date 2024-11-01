import Metal

extension MTLVertexDescriptor {
    convenience init(vertexAttributes: [MTLVertexAttribute]) {
        self.init()
        var offset: Int = 0
        for (index, attribute) in vertexAttributes.enumerated() {
            let format = MTLVertexFormat(attribute.attributeType)
            attributes[index].format = format
            attributes[index].bufferIndex = 0
            attributes[index].offset = offset
            offset += format.size
        }
        layouts[0].stride = offset
    }
}

extension MTLVertexFormat {
    init(_ dataType: MTLDataType) {
        switch dataType {
        case .float3:
            self = .float3
        default:
            fatalError()
        }
    }

    var size: Int {
        switch self {
        case .float3:
            return MemoryLayout<SIMD3<Float>>.size
        default:
            fatalError()
        }
    }
}
