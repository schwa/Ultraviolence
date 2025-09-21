import Metal
import Collections

struct VertexDescriptor: Equatable, Sendable {
    struct Attribute: Equatable, Sendable {
        enum Semantic: Equatable, Sendable {
            case unknown
            case position
            case normal
            case tangent
            case bitangent
            case texcoord
            case color
            case userDefined
        }

        var label: String?
        var semantic: Semantic
        var format: MTLVertexFormat
        var offset: Int
        var bufferIndex: Int
    }

    struct Layout: Equatable, Sendable {
        var bufferIndex: Int
        var stride: Int
        var stepFunction: MTLVertexStepFunction
        var stepRate: Int
    }

    var label: String?
    var attributes: [Attribute]
    var layouts: OrderedDictionary<Int, Layout>

    init(label: String? = nil, attributes: [Attribute], layouts: [Layout]) {
        self.label = label
        self.attributes = attributes
        self.layouts = .init(uniqueKeysWithValues: layouts.map { ($0.bufferIndex, $0) })
    }
}

extension VertexDescriptor: CustomDebugStringConvertible {
    var debugDescription: String {
        "VertexDescriptor(\(label.map { "label: \($0), " } ?? "")attributes: \(attributes), layouts: \(layouts))"
    }
}


extension VertexDescriptor.Attribute: CustomDebugStringConvertible {
    var debugDescription: String {
        "Attribute(\(label.map { "label: \($0), " }  ?? "")semantic: \(semantic), format: \(format), offset: \(offset), bufferIndex: \(bufferIndex))"
    }
}

extension VertexDescriptor.Layout: CustomDebugStringConvertible {
    var debugDescription: String {
        "Layout(bufferIndex: \(bufferIndex), stride: \(stride), stepFunction: \(stepFunction), stepRate: \(stepRate))"
    }
}

extension VertexDescriptor.Layout {
    init(bufferIndex: Int) {
        self.init(bufferIndex: bufferIndex, stride: 0, stepFunction: .perVertex, stepRate: 0) // TODO: Is 1 the default stepRate? [FILE ME]
    }
}

extension VertexDescriptor {
    func dump() {
        print("VertexDescriptor: \(label ?? "nil")")
        print("Attributes:")
        for attribute in attributes {
            print("  - \(attribute)")
        }
        print("Layouts:")
        for layout in layouts.values {
            print("  - \(layout)")
        }
    }
}

extension VertexDescriptor {
    func normalized() -> Self {
        let result = normalizingOffsets().normalizingStrides()
        return result
    }

    func normalizingOffsets() -> Self {
        var copy = self
        var offsetsPerBufferIndex: [Int: Int] = [:]
        copy.attributes = copy.attributes.map { attribute in
            let currentOffset = offsetsPerBufferIndex[attribute.bufferIndex, default: 0]
            var attribute = attribute
            attribute.offset = currentOffset
            offsetsPerBufferIndex[attribute.bufferIndex] = currentOffset + attribute.format.size
            return attribute
        }
        return copy
    }

    func normalizingStrides() -> Self {
        var copy = self
        for (bufferIndex, layout) in copy.layouts {
            let maxOffset = copy.attributes
                .filter { $0.bufferIndex == bufferIndex }
                .map { $0.offset + $0.format.size }
                .max() ?? 0
            var layout = layout
            layout.stride = maxOffset
            copy.layouts[bufferIndex] = layout
        }
        return copy
    }
}

extension VertexDescriptor {
    init(_ mtlVertexDescriptor: MTLVertexDescriptor) {
        var attributes: [Attribute] = []
        var layouts: [Layout] = []

        // Convert attributes
        for index in 0..<31 { // Metal supports up to 31 vertex attributes
            guard let mtlAttribute = mtlVertexDescriptor.attributes[index],
                  mtlAttribute.format != .invalid else { continue }

            let attribute = Attribute(
                label: nil,
                semantic: .userDefined, // We can't infer semantic from MTLVertexDescriptor
                format: mtlAttribute.format,
                offset: mtlAttribute.offset,
                bufferIndex: mtlAttribute.bufferIndex
            )
            attributes.append(attribute)
        }

        // Convert layouts
        for bufferIndex in 0..<31 { // Metal supports up to 31 vertex buffer layouts
            guard let mtlLayout = mtlVertexDescriptor.layouts[bufferIndex],
                  mtlLayout.stride > 0 else { continue }

            let layout = Layout(
                bufferIndex: bufferIndex,
                stride: mtlLayout.stride,
                stepFunction: mtlLayout.stepFunction,
                stepRate: mtlLayout.stepRate
            )
            layouts.append(layout)
        }

        self.init(label: nil, attributes: attributes, layouts: layouts)
    }

    var mtlVertexDescriptor: MTLVertexDescriptor {
        let mtlVertexDescriptor = MTLVertexDescriptor()
        for (index, attribute) in attributes.enumerated() {
            let mtlAttribute = mtlVertexDescriptor.attributes[index]!
            mtlAttribute.format = attribute.format
            mtlAttribute.offset = attribute.offset
            mtlAttribute.bufferIndex = attribute.bufferIndex
        }
        for (bufferIndex, layout) in layouts {
            let mtlLayout = mtlVertexDescriptor.layouts[bufferIndex]!
            mtlLayout.stride = layout.stride
            mtlLayout.stepFunction = layout.stepFunction
            mtlLayout.stepRate = layout.stepRate
        }
        return mtlVertexDescriptor
    }
}

extension MTLVertexDescriptor {
    convenience init(_ vertexDescriptor: VertexDescriptor) {
        self.init()

        // Set up attributes
        for (index, attribute) in vertexDescriptor.attributes.enumerated() {
            let mtlAttribute = attributes[index]!
            mtlAttribute.format = attribute.format
            mtlAttribute.offset = attribute.offset
            mtlAttribute.bufferIndex = attribute.bufferIndex
        }

        // Set up layouts
        for (bufferIndex, layout) in vertexDescriptor.layouts {
            let mtlLayout = layouts[bufferIndex]!
            mtlLayout.stride = layout.stride
            mtlLayout.stepFunction = layout.stepFunction
            mtlLayout.stepRate = layout.stepRate
        }
    }
}

extension MTLVertexFormat {
    var size: Int {
        switch self {
        case .invalid:
            fatalError("Invalid vertex format")
        case .uchar2:
            return MemoryLayout<UInt8>.size * 2
        case .uchar3:
            return MemoryLayout<UInt8>.size * 3
        case .uchar4:
            return MemoryLayout<UInt8>.size * 4
        case .char2:
            return MemoryLayout<Int8>.size * 2
        case .char3:
            return MemoryLayout<Int8>.size * 3
        case .char4:
            return MemoryLayout<Int8>.size * 4
        case .uchar2Normalized:
            return MemoryLayout<UInt8>.size * 2
        case .uchar3Normalized:
            return MemoryLayout<UInt8>.size * 3
        case .uchar4Normalized:
            return MemoryLayout<UInt8>.size * 4
        case .char2Normalized:
            return MemoryLayout<Int8>.size * 2
        case .char3Normalized:
            return MemoryLayout<Int8>.size * 3
        case .char4Normalized:
            return MemoryLayout<Int8>.size * 4
        case .ushort2:
            return MemoryLayout<UInt16>.size * 2
        case .ushort3:
            return MemoryLayout<UInt16>.size * 3
        case .ushort4:
            return MemoryLayout<UInt16>.size * 4
        case .short2:
            return MemoryLayout<Int16>.size * 2
        case .short3:
            return MemoryLayout<Int16>.size * 3
        case .short4:
            return MemoryLayout<Int16>.size * 4
        case .ushort2Normalized:
            return MemoryLayout<UInt16>.size * 2
        case .ushort3Normalized:
            return MemoryLayout<UInt16>.size * 3
        case .ushort4Normalized:
            return MemoryLayout<UInt16>.size * 4
        case .short2Normalized:
            return MemoryLayout<Int16>.size * 2
        case .short3Normalized:
            return MemoryLayout<Int16>.size * 3
        case .short4Normalized:
            return MemoryLayout<Int16>.size * 4
        case .half2:
            return MemoryLayout<Float16>.size * 2
        case .half3:
            return MemoryLayout<Float16>.size * 3
        case .half4:
            return MemoryLayout<Float16>.size * 4
        case .float:
            return MemoryLayout<Float>.size
        case .float2:
            return MemoryLayout<Float>.size * 2
        case .float3:
            return MemoryLayout<Float>.size * 3
        case .float4:
            return MemoryLayout<Float>.size * 4
        case .int:
            return MemoryLayout<Int32>.size
        case .int2:
            return MemoryLayout<Int32>.size * 2
        case .int3:
            return MemoryLayout<Int32>.size * 3
        case .int4:
            return MemoryLayout<Int32>.size * 4
        case .uint:
            return MemoryLayout<UInt32>.size
        case .uint2:
            return MemoryLayout<UInt32>.size * 2
        case .uint3:
            return MemoryLayout<UInt32>.size * 3
        case .uint4:
            return MemoryLayout<UInt32>.size * 4
        case .int1010102Normalized:
            return MemoryLayout<UInt32>.size
        case .uint1010102Normalized:
            return MemoryLayout<UInt32>.size
        case .uchar4Normalized_bgra:
            return MemoryLayout<UInt8>.size * 4
        case .uchar:
            return MemoryLayout<UInt8>.size
        case .char:
            return MemoryLayout<Int8>.size
        case .ucharNormalized:
            return MemoryLayout<UInt8>.size
        case .charNormalized:
            return MemoryLayout<Int8>.size
        case .ushort:
            return MemoryLayout<UInt16>.size
        case .short:
            return MemoryLayout<Int16>.size
        case .ushortNormalized:
            return MemoryLayout<UInt16>.size
        case .shortNormalized:
            return MemoryLayout<Int16>.size
        case .half:
            return MemoryLayout<Float16>.size
        case .floatRG11B10:
            return MemoryLayout<UInt32>.size
        case .floatRGB9E5:
            return MemoryLayout<UInt32>.size
        @unknown default:
            fatalError("Unknown vertex format")
        }
    }
}

extension MTLVertexFormat: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .invalid:
            return "invalid"
        case .uchar2:
            return "uchar2"
        case .uchar3:
            return "uchar3"
        case .uchar4:
            return "uchar4"
        case .char2:
            return "char2"
        case .char3:
            return "char3"
        case .char4:
            return "char4"
        case .uchar2Normalized:
            return "uchar2Normalized"
        case .uchar3Normalized:
            return "uchar3Normalized"
        case .uchar4Normalized:
            return "uchar4Normalized"
        case .char2Normalized:
            return "char2Normalized"
        case .char3Normalized:
            return "char3Normalized"
        case .char4Normalized:
            return "char4Normalized"
        case .ushort2:
            return "ushort2"
        case .ushort3:
            return "ushort3"
        case .ushort4:
            return "ushort4"
        case .short2:
            return "short2"
        case .short3:
            return "short3"
        case .short4:
            return "short4"
        case .ushort2Normalized:
            return "ushort2Normalized"
        case .ushort3Normalized:
            return "ushort3Normalized"
        case .ushort4Normalized:
            return "ushort4Normalized"
        case .short2Normalized:
            return "short2Normalized"
        case .short3Normalized:
            return "short3Normalized"
        case .short4Normalized:
            return "short4Normalized"
        case .half2:
            return "half2"
        case .half3:
            return "half3"
        case .half4:
            return "half4"
        case .float:
            return "float"
        case .float2:
            return "float2"
        case .float3:
            return "float3"
        case .float4:
            return "float4"
        case .int:
            return "int"
        case .int2:
            return "int2"
        case .int3:
            return "int3"
        case .int4:
            return "int4"
        case .uint:
            return "uint"
        case .uint2:
            return "uint2"
        case .uint3:
            return "uint3"
        case .uint4:
            return "uint4"
        case .int1010102Normalized:
            return "int1010102Normalized"
        case .uint1010102Normalized:
            return "uint1010102Normalized"
        case .uchar4Normalized_bgra:
            return "uchar4Normalized_bgra"
        case .uchar:
            return "uchar"
        case .char:
            return "char"
        case .ucharNormalized:
            return "ucharNormalized"
        case .charNormalized:
            return "charNormalized"
        case .ushort:
            return "ushort"
        case .short:
            return "short"
        case .ushortNormalized:
            return "ushortNormalized"
        case .shortNormalized:
            return "shortNormalized"
        case .half:
            return "half"
        case .floatRG11B10:
            return "floatRG11B10"
        case .floatRGB9E5:
            return "floatRGB9E5"
        @unknown default:
            return "unknown"
        }
    }
}


extension MTLVertexStepFunction: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .constant:
            return "constant"
        case .perVertex:
            return "perVertex"
        case .perInstance:
            return "perInstance"
        case .perPatch:
            return "perPatch"
        case .perPatchControlPoint:
            return "perPatchControlPoint"
        @unknown default:
            return "unknown"
        }
    }
}

