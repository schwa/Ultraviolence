import Testing
import Metal
@testable import UltraviolenceExamples

struct VertexDescriptorTests {

    @Test
    func testAttributeInitialization() {
        let attribute = VertexDescriptor.Attribute(
            label: "position",
            semantic: .position,
            format: .float3,
            offset: 0,
            bufferIndex: 0
        )

        #expect(attribute.label == "position")
        #expect(attribute.semantic == .position)
        #expect(attribute.format == .float3)
        #expect(attribute.offset == 0)
        #expect(attribute.bufferIndex == 0)
    }

    @Test
    func testLayoutInitialization() {
        let layout = VertexDescriptor.Layout(
            bufferIndex: 0,
            stride: 32,
            stepFunction: .perVertex,
            stepRate: 1
        )

        #expect(layout.bufferIndex == 0)
        #expect(layout.stride == 32)
        #expect(layout.stepFunction == .perVertex)
        #expect(layout.stepRate == 1)
    }

    @Test
    func testLayoutDefaultInitialization() {
        let layout = VertexDescriptor.Layout(bufferIndex: 1)

        #expect(layout.bufferIndex == 1)
        #expect(layout.stride == 0)
        #expect(layout.stepFunction == .perVertex)
        #expect(layout.stepRate == 1)
    }

    @Test
    func testVertexDescriptorInitialization() {
        let attributes = [
            VertexDescriptor.Attribute(label: "position", semantic: .position, format: .float3, offset: 0, bufferIndex: 0),
            VertexDescriptor.Attribute(label: "normal", semantic: .normal, format: .float3, offset: 12, bufferIndex: 0)
        ]

        let layouts = [
            VertexDescriptor.Layout(bufferIndex: 0, stride: 24, stepFunction: .perVertex, stepRate: 1)
        ]

        let descriptor = VertexDescriptor(label: "test", attributes: attributes, layouts: layouts)

        #expect(descriptor.label == "test")
        #expect(descriptor.attributes.count == 2)
        #expect(descriptor.attributes[0].semantic == .position)
        #expect(descriptor.attributes[0].format == .float3)
        #expect(descriptor.attributes[1].semantic == .normal)
        #expect(descriptor.attributes[1].offset == 12)
        #expect(descriptor.layouts[0]?.stride == 24)
    }

    @Test
    func testNormalizingOffsets() {
        // Create a descriptor with incorrect offsets
        let attributes = [
            VertexDescriptor.Attribute(label: "position", semantic: .position, format: .float3, offset: 100, bufferIndex: 0),
            VertexDescriptor.Attribute(label: "normal", semantic: .normal, format: .float3, offset: 200, bufferIndex: 0),
            VertexDescriptor.Attribute(label: "texcoord", semantic: .texcoord, format: .float2, offset: 300, bufferIndex: 0)
        ]

        let layouts = [
            VertexDescriptor.Layout(bufferIndex: 0)
        ]

        let descriptor = VertexDescriptor(attributes: attributes, layouts: layouts)
        let normalized = descriptor.normalizingOffsets()

        // After normalization, offsets should increment for each attribute in the same buffer
        let positionAttr = normalized.attributes.first { $0.semantic == .position }
        let normalAttr = normalized.attributes.first { $0.semantic == .normal }
        let texcoordAttr = normalized.attributes.first { $0.semantic == .texcoord }
        #expect(positionAttr?.offset == 0)
        #expect(normalAttr?.offset == 12) // float3 = 12 bytes
        #expect(texcoordAttr?.offset == 24) // 12 + 12 = 24
    }

    @Test
    func testNormalizingOffsetsMultipleBuffers() {
        // Test with attributes in different buffers
        let attributes = [
            VertexDescriptor.Attribute(label: "position", semantic: .position, format: .float3, offset: 100, bufferIndex: 0),
            VertexDescriptor.Attribute(label: "normal", semantic: .normal, format: .float3, offset: 200, bufferIndex: 0),
            VertexDescriptor.Attribute(label: "texcoord", semantic: .texcoord, format: .float2, offset: 300, bufferIndex: 1),
            VertexDescriptor.Attribute(label: "color", semantic: .color, format: .float4, offset: 400, bufferIndex: 1)
        ]

        let layouts = [
            VertexDescriptor.Layout(bufferIndex: 0),
            VertexDescriptor.Layout(bufferIndex: 1)
        ]

        let descriptor = VertexDescriptor(attributes: attributes, layouts: layouts)
        let normalized = descriptor.normalizingOffsets()

        // Each buffer should have offsets starting from 0
        let positionAttr = normalized.attributes.first { $0.semantic == .position }
        let normalAttr = normalized.attributes.first { $0.semantic == .normal }
        let texcoordAttr = normalized.attributes.first { $0.semantic == .texcoord }
        let colorAttr = normalized.attributes.first { $0.semantic == .color }

        // Buffer 0 attributes
        #expect(positionAttr?.offset == 0)
        #expect(normalAttr?.offset == 12) // position (float3) = 12 bytes

        // Buffer 1 attributes
        #expect(texcoordAttr?.offset == 0)
        #expect(colorAttr?.offset == 8) // texcoord (float2) = 8 bytes
    }

    @Test
    func testNormalizingStrides() {
        let attributes = [
            VertexDescriptor.Attribute(label: "position", semantic: .position, format: .float3, offset: 0, bufferIndex: 0),
            VertexDescriptor.Attribute(label: "normal", semantic: .normal, format: .float3, offset: 12, bufferIndex: 0),
            VertexDescriptor.Attribute(label: "texcoord", semantic: .texcoord, format: .float2, offset: 24, bufferIndex: 0)
        ]

        let layouts = [
            VertexDescriptor.Layout(bufferIndex: 0, stride: 0, stepFunction: .perVertex, stepRate: 1)
        ]

        let descriptor = VertexDescriptor(attributes: attributes, layouts: layouts)
        let normalized = descriptor.normalizingStrides()

        // Stride should be calculated as max(offset + size) for all attributes in the buffer
        // position: offset 0 + size 12 = 12
        // normal: offset 12 + size 12 = 24
        // texcoord: offset 24 + size 8 = 32
        #expect(normalized.layouts[0]?.stride == 32)
    }

    @Test
    func testNormalizingStridesMultipleBuffers() {
        let attributes = [
            VertexDescriptor.Attribute(label: "position", semantic: .position, format: .float3, offset: 0, bufferIndex: 0),
            VertexDescriptor.Attribute(label: "normal", semantic: .normal, format: .float3, offset: 12, bufferIndex: 0),
            VertexDescriptor.Attribute(label: "texcoord", semantic: .texcoord, format: .float2, offset: 0, bufferIndex: 1),
            VertexDescriptor.Attribute(label: "color", semantic: .color, format: .float4, offset: 8, bufferIndex: 1)
        ]

        let layouts = [
            VertexDescriptor.Layout(bufferIndex: 0, stride: 0, stepFunction: .perVertex, stepRate: 1),
            VertexDescriptor.Layout(bufferIndex: 1, stride: 0, stepFunction: .perVertex, stepRate: 1)
        ]

        let descriptor = VertexDescriptor(attributes: attributes, layouts: layouts)
        let normalized = descriptor.normalizingStrides()

        // Buffer 0: normal at offset 12 + size 12 = 24
        #expect(normalized.layouts[0]?.stride == 24)
        // Buffer 1: color at offset 8 + size 16 = 24
        #expect(normalized.layouts[1]?.stride == 24)
    }

    @Test
    func testMTLVertexDescriptorConversion() {
        let attributes = [
            VertexDescriptor.Attribute(label: "position", semantic: .position, format: .float3, offset: 0, bufferIndex: 0),
            VertexDescriptor.Attribute(label: "normal", semantic: .normal, format: .float3, offset: 12, bufferIndex: 0)
        ]

        let layouts = [
            VertexDescriptor.Layout(bufferIndex: 0, stride: 24, stepFunction: .perVertex, stepRate: 1)
        ]

        let descriptor = VertexDescriptor(attributes: attributes, layouts: layouts)
        let mtlDescriptor = descriptor.mtlVertexDescriptor

        // Check attribute 0 (position)
        #expect(mtlDescriptor.attributes[0].format == .float3)
        #expect(mtlDescriptor.attributes[0].offset == 0)
        #expect(mtlDescriptor.attributes[0].bufferIndex == 0)

        // Check attribute 1 (normal)
        #expect(mtlDescriptor.attributes[1].format == .float3)
        #expect(mtlDescriptor.attributes[1].offset == 12)
        #expect(mtlDescriptor.attributes[1].bufferIndex == 0)

        // Check layout
        #expect(mtlDescriptor.layouts[0].stride == 24)
        #expect(mtlDescriptor.layouts[0].stepFunction == .perVertex)
        #expect(mtlDescriptor.layouts[0].stepRate == 1)
    }

    @Test
    func testMTLVertexDescriptorConvenienceInit() {
        let attributes = [
            VertexDescriptor.Attribute(label: "position", semantic: .position, format: .float3, offset: 0, bufferIndex: 0),
            VertexDescriptor.Attribute(label: "texcoord", semantic: .texcoord, format: .float2, offset: 12, bufferIndex: 0)
        ]

        let layouts = [
            VertexDescriptor.Layout(bufferIndex: 0, stride: 20, stepFunction: .perInstance, stepRate: 2)
        ]

        let descriptor = VertexDescriptor(attributes: attributes, layouts: layouts)
        let mtlDescriptor = MTLVertexDescriptor(descriptor)

        // Check attribute 0 (position)
        #expect(mtlDescriptor.attributes[0].format == .float3)
        #expect(mtlDescriptor.attributes[0].offset == 0)
        #expect(mtlDescriptor.attributes[0].bufferIndex == 0)

        // Check attribute 1 (texcoord)
        #expect(mtlDescriptor.attributes[1].format == .float2)
        #expect(mtlDescriptor.attributes[1].offset == 12)
        #expect(mtlDescriptor.attributes[1].bufferIndex == 0)

        // Check layout
        #expect(mtlDescriptor.layouts[0].stride == 20)
        #expect(mtlDescriptor.layouts[0].stepFunction == .perInstance)
        #expect(mtlDescriptor.layouts[0].stepRate == 2)
    }

    @Test
    func testVertexFormatSizes() {
        // Test various vertex format sizes
        #expect(MTLVertexFormat.float.size == 4)
        #expect(MTLVertexFormat.float2.size == 8)
        #expect(MTLVertexFormat.float3.size == 12)
        #expect(MTLVertexFormat.float4.size == 16)

        #expect(MTLVertexFormat.half.size == 2)
        #expect(MTLVertexFormat.half2.size == 4)
        #expect(MTLVertexFormat.half3.size == 6)
        #expect(MTLVertexFormat.half4.size == 8)

        #expect(MTLVertexFormat.int.size == 4)
        #expect(MTLVertexFormat.int2.size == 8)
        #expect(MTLVertexFormat.int3.size == 12)
        #expect(MTLVertexFormat.int4.size == 16)

        #expect(MTLVertexFormat.uint.size == 4)
        #expect(MTLVertexFormat.uint2.size == 8)
        #expect(MTLVertexFormat.uint3.size == 12)
        #expect(MTLVertexFormat.uint4.size == 16)

        #expect(MTLVertexFormat.short.size == 2)
        #expect(MTLVertexFormat.short2.size == 4)
        #expect(MTLVertexFormat.short3.size == 6)
        #expect(MTLVertexFormat.short4.size == 8)

        #expect(MTLVertexFormat.ushort.size == 2)
        #expect(MTLVertexFormat.ushort2.size == 4)
        #expect(MTLVertexFormat.ushort3.size == 6)
        #expect(MTLVertexFormat.ushort4.size == 8)

        #expect(MTLVertexFormat.char.size == 1)
        #expect(MTLVertexFormat.char2.size == 2)
        #expect(MTLVertexFormat.char3.size == 3)
        #expect(MTLVertexFormat.char4.size == 4)

        #expect(MTLVertexFormat.uchar.size == 1)
        #expect(MTLVertexFormat.uchar2.size == 2)
        #expect(MTLVertexFormat.uchar3.size == 3)
        #expect(MTLVertexFormat.uchar4.size == 4)

        // Normalized formats should have the same size
        #expect(MTLVertexFormat.charNormalized.size == 1)
        #expect(MTLVertexFormat.char2Normalized.size == 2)
        #expect(MTLVertexFormat.char3Normalized.size == 3)
        #expect(MTLVertexFormat.char4Normalized.size == 4)

        #expect(MTLVertexFormat.ucharNormalized.size == 1)
        #expect(MTLVertexFormat.uchar2Normalized.size == 2)
        #expect(MTLVertexFormat.uchar3Normalized.size == 3)
        #expect(MTLVertexFormat.uchar4Normalized.size == 4)

        #expect(MTLVertexFormat.shortNormalized.size == 2)
        #expect(MTLVertexFormat.short2Normalized.size == 4)
        #expect(MTLVertexFormat.short3Normalized.size == 6)
        #expect(MTLVertexFormat.short4Normalized.size == 8)

        #expect(MTLVertexFormat.ushortNormalized.size == 2)
        #expect(MTLVertexFormat.ushort2Normalized.size == 4)
        #expect(MTLVertexFormat.ushort3Normalized.size == 6)
        #expect(MTLVertexFormat.ushort4Normalized.size == 8)

        // Special formats
        #expect(MTLVertexFormat.int1010102Normalized.size == 4)
        #expect(MTLVertexFormat.uint1010102Normalized.size == 4)
        #expect(MTLVertexFormat.uchar4Normalized_bgra.size == 4)
        #expect(MTLVertexFormat.floatRG11B10.size == 4)
        #expect(MTLVertexFormat.floatRGB9E5.size == 4)
    }

    @Test
    func testAttributeSemantics() {
        let semantics: [VertexDescriptor.Attribute.Semantic] = [
            .unknown,
            .position,
            .normal,
            .tangent,
            .bitangent,
            .texcoord,
            .color,
            .userDefined
        ]

        // Just test that all semantics can be used
        for semantic in semantics {
            let attribute = VertexDescriptor.Attribute(
                label: nil,
                semantic: semantic,
                format: .float3,
                offset: 0,
                bufferIndex: 0
            )
            #expect(attribute.semantic == semantic)
        }
    }

    @Test
    func testEquatable() {
        let attr1 = VertexDescriptor.Attribute(label: "pos", semantic: .position, format: .float3, offset: 0, bufferIndex: 0)
        let attr2 = VertexDescriptor.Attribute(label: "pos", semantic: .position, format: .float3, offset: 0, bufferIndex: 0)
        let attr3 = VertexDescriptor.Attribute(label: "norm", semantic: .normal, format: .float3, offset: 12, bufferIndex: 0)

        #expect(attr1 == attr2)
        #expect(attr1 != attr3)

        let layout1 = VertexDescriptor.Layout(bufferIndex: 0, stride: 24, stepFunction: .perVertex, stepRate: 1)
        let layout2 = VertexDescriptor.Layout(bufferIndex: 0, stride: 24, stepFunction: .perVertex, stepRate: 1)
        let layout3 = VertexDescriptor.Layout(bufferIndex: 1, stride: 32, stepFunction: .perInstance, stepRate: 2)

        #expect(layout1 == layout2)
        #expect(layout1 != layout3)

        let desc1 = VertexDescriptor(label: "test", attributes: [attr1], layouts: [layout1])
        let desc2 = VertexDescriptor(label: "test", attributes: [attr2], layouts: [layout2])
        let desc3 = VertexDescriptor(label: "test2", attributes: [attr3], layouts: [layout3])

        #expect(desc1 == desc2)
        #expect(desc1 != desc3)
    }

    @Test
    func testInitFromMTLVertexDescriptor() {
        // Create an MTLVertexDescriptor
        let mtlDescriptor = MTLVertexDescriptor()

        // Set up some attributes
        mtlDescriptor.attributes[0].format = .float3
        mtlDescriptor.attributes[0].offset = 0
        mtlDescriptor.attributes[0].bufferIndex = 0

        mtlDescriptor.attributes[1].format = .float2
        mtlDescriptor.attributes[1].offset = 12
        mtlDescriptor.attributes[1].bufferIndex = 0

        mtlDescriptor.attributes[2].format = .float4
        mtlDescriptor.attributes[2].offset = 0
        mtlDescriptor.attributes[2].bufferIndex = 1

        // Set up layouts
        mtlDescriptor.layouts[0].stride = 20
        mtlDescriptor.layouts[0].stepFunction = .perVertex
        mtlDescriptor.layouts[0].stepRate = 1

        mtlDescriptor.layouts[1].stride = 16
        mtlDescriptor.layouts[1].stepFunction = .perInstance
        mtlDescriptor.layouts[1].stepRate = 2

        // Convert to VertexDescriptor
        let vertexDescriptor = VertexDescriptor(mtlDescriptor)

        // Check that attributes were converted correctly
        #expect(vertexDescriptor.attributes.count == 3)

        // Since we can't infer semantic, all should be .userDefined
        for attribute in vertexDescriptor.attributes {
            #expect(attribute.semantic == .userDefined)
        }

        // Check specific attribute properties
        let attr0 = vertexDescriptor.attributes[0]
        #expect(attr0.format == .float3)
        #expect(attr0.offset == 0)
        #expect(attr0.bufferIndex == 0)

        let attr1 = vertexDescriptor.attributes[1]
        #expect(attr1.format == .float2)
        #expect(attr1.offset == 12)
        #expect(attr1.bufferIndex == 0)

        let attr2 = vertexDescriptor.attributes[2]
        #expect(attr2.format == .float4)
        #expect(attr2.offset == 0)
        #expect(attr2.bufferIndex == 1)

        // Check layouts
        #expect(vertexDescriptor.layouts[0]?.stride == 20)
        #expect(vertexDescriptor.layouts[0]?.stepFunction == .perVertex)
        #expect(vertexDescriptor.layouts[0]?.stepRate == 1)

        #expect(vertexDescriptor.layouts[1]?.stride == 16)
        #expect(vertexDescriptor.layouts[1]?.stepFunction == .perInstance)
        #expect(vertexDescriptor.layouts[1]?.stepRate == 2)
    }

    @Test
    func testRoundTripConversion() {
        // Create a VertexDescriptor
        let originalAttributes = [
            VertexDescriptor.Attribute(label: "position", semantic: .position, format: .float3, offset: 0, bufferIndex: 0),
            VertexDescriptor.Attribute(label: "texcoord", semantic: .texcoord, format: .float2, offset: 12, bufferIndex: 0)
        ]

        let originalLayouts = [
            VertexDescriptor.Layout(bufferIndex: 0, stride: 20, stepFunction: .perVertex, stepRate: 1)
        ]

        let original = VertexDescriptor(attributes: originalAttributes, layouts: originalLayouts)

        // Convert to MTLVertexDescriptor and back
        let mtlDescriptor = original.mtlVertexDescriptor
        let roundTrip = VertexDescriptor(mtlDescriptor)

        // Check that the basic properties survived the round trip
        #expect(roundTrip.attributes.count == 2)
        #expect(roundTrip.layouts.count == 1)

        // Note: We lose semantic information in the round trip since MTLVertexDescriptor doesn't store it
        #expect(roundTrip.attributes[0].format == .float3)
        #expect(roundTrip.attributes[0].offset == 0)
        #expect(roundTrip.attributes[0].bufferIndex == 0)

        #expect(roundTrip.attributes[1].format == .float2)
        #expect(roundTrip.attributes[1].offset == 12)
        #expect(roundTrip.attributes[1].bufferIndex == 0)

        #expect(roundTrip.layouts[0]?.stride == 20)
        #expect(roundTrip.layouts[0]?.stepFunction == .perVertex)
        #expect(roundTrip.layouts[0]?.stepRate == 1)
    }

    @Test
    func testComplexNormalization() {
        // Test a complex scenario with multiple buffers and attributes
        let attributes = [
            VertexDescriptor.Attribute(label: "position", semantic: .position, format: .float3, offset: 100, bufferIndex: 0),
            VertexDescriptor.Attribute(label: "normal", semantic: .normal, format: .float3, offset: 200, bufferIndex: 0),
            VertexDescriptor.Attribute(label: "tangent", semantic: .tangent, format: .float3, offset: 300, bufferIndex: 0),
            VertexDescriptor.Attribute(label: "texcoord", semantic: .texcoord, format: .float2, offset: 400, bufferIndex: 1),
            VertexDescriptor.Attribute(label: "color", semantic: .color, format: .uchar4Normalized, offset: 500, bufferIndex: 1)
        ]

        let layouts = [
            VertexDescriptor.Layout(bufferIndex: 0, stride: 999, stepFunction: .perVertex, stepRate: 1),
            VertexDescriptor.Layout(bufferIndex: 1, stride: 888, stepFunction: .perInstance, stepRate: 3)
        ]

        let descriptor = VertexDescriptor(attributes: attributes, layouts: layouts)

        // Normalize offsets first
        let normalizedOffsets = descriptor.normalizingOffsets()
        let posAttr = normalizedOffsets.attributes.first { $0.semantic == .position }
        let normAttr = normalizedOffsets.attributes.first { $0.semantic == .normal }
        let tanAttr = normalizedOffsets.attributes.first { $0.semantic == .tangent }
        let texAttr = normalizedOffsets.attributes.first { $0.semantic == .texcoord }
        let colAttr = normalizedOffsets.attributes.first { $0.semantic == .color }

        // Buffer 0: position, normal, tangent should be sequential
        #expect(posAttr?.offset == 0)
        #expect(normAttr?.offset == 12) // position (float3) = 12
        #expect(tanAttr?.offset == 24) // + normal (float3) = 24

        // Buffer 1: texcoord, color should be sequential
        #expect(texAttr?.offset == 0)
        #expect(colAttr?.offset == 8) // texcoord (float2) = 8

        // Then normalize strides on the already offset-normalized descriptor
        let fullyNormalized = normalizedOffsets.normalizingStrides()

        // Buffer 0 should have stride = last offset + size
        // tangent at offset 24 + size 12 = 36
        #expect(fullyNormalized.layouts[0]?.stride == 36)

        // Buffer 1 should have stride = last offset + size
        // color at offset 8 + size 4 = 12
        #expect(fullyNormalized.layouts[1]?.stride == 12)

        // Step functions and rates should be preserved
        #expect(fullyNormalized.layouts[0]?.stepFunction == .perVertex)
        #expect(fullyNormalized.layouts[0]?.stepRate == 1)
        #expect(fullyNormalized.layouts[1]?.stepFunction == .perInstance)
        #expect(fullyNormalized.layouts[1]?.stepRate == 3)
    }
}