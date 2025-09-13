import Metal
import MetalKit

public extension MTKMesh {
    convenience init(name: String, bundle: Bundle) throws {
        let device = _MTLCreateSystemDefaultDevice()
        let teapotURL = bundle.url(forResource: name, withExtension: "obj")
        let vertexDescriptor = MDLVertexDescriptor()
        vertexDescriptor.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition, format: .float3, offset: 0, bufferIndex: 0)
        vertexDescriptor.attributes[1] = MDLVertexAttribute(name: MDLVertexAttributeNormal, format: .float3, offset: MemoryLayout<Float>.stride * 3, bufferIndex: 0)
        vertexDescriptor.attributes[2] = MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate, format: .float2, offset: MemoryLayout<Float>.stride * 6, bufferIndex: 0)
        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: MemoryLayout<Float>.stride * 8)
        let mdlAsset = MDLAsset(url: teapotURL, vertexDescriptor: vertexDescriptor, bufferAllocator: MTKMeshBufferAllocator(device: device))
        let mdlMesh = (mdlAsset.object(at: 0) as? MDLMesh).orFatalError(.resourceCreationFailure("Failed to load teapot mesh."))
        try self.init(mesh: mdlMesh, device: device)
    }

    static func teapot() -> MTKMesh {
        do {
            return try MTKMesh(name: "teapot", bundle: .main)
        }
        catch {
            fatalError("\(error)")
        }
    }

    static func sphere(extent: SIMD3<Float> = [1, 1, 1], inwardNormals: Bool = false) -> MTKMesh {
        do {
            let device = _MTLCreateSystemDefaultDevice()
            let allocator = MTKMeshBufferAllocator(device: device)
            let mdlMesh = MDLMesh(sphereWithExtent: extent, segments: [48, 48], inwardNormals: inwardNormals, geometryType: .triangles, allocator: allocator)
            return try MTKMesh(mesh: mdlMesh, device: device)
        }
        catch {
            fatalError("\(error)")
        }
    }

    static func plane(width: Float = 1, height: Float = 1, segments: SIMD2<UInt32> = [2, 2]) -> MTKMesh {
        do {
            let device = _MTLCreateSystemDefaultDevice()
            let allocator = MTKMeshBufferAllocator(device: device)
            let mdlMesh = MDLMesh(planeWithExtent: [width, height, 0], segments: segments, geometryType: .triangles, allocator: allocator)
            return try MTKMesh(mesh: mdlMesh, device: device)
        }
        catch {
            fatalError("\(error)")
        }
    }
}

public extension MTLDevice {
    func makeTexture(name: String, bundle: Bundle? = nil) throws -> MTLTexture {
        let textureLoader = MTKTextureLoader(device: self)
        return try textureLoader.newTexture(name: name, scaleFactor: 1.0, bundle: bundle)
    }
}

// swiftlint:disable file_length

import CoreGraphics
import ImageIO
import ModelIO
import simd
import SwiftUI
import UniformTypeIdentifiers
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

public extension MTLVertexDescriptor {
    convenience init(vertexAttributes: [MTLVertexAttribute]) {
        self.init()
        var offset: Int = 0
        for (index, attribute) in vertexAttributes.enumerated() {
            let format = MTLVertexFormat(attribute.attributeType)
            attributes[index].format = format
            attributes[index].bufferIndex = 0
            attributes[index].offset = offset
            offset += format.size(packed: true)
        }
        layouts[0].stride = offset
    }
}

public extension MTLVertexFormat {
    init(_ dataType: MTLDataType) {
        switch dataType {
        case .float3:
            self = .float3

        case .float2:
            self = .float2

        default:
            fatalError("Unimplemented")
        }
    }

    func size(packed: Bool) -> Int {
        switch self {
        case .float3:
            return packed ? MemoryLayout<Float>.stride * 3 : MemoryLayout<SIMD3<Float>>.size

        case .float2:
            return MemoryLayout<SIMD2<Float>>.size

        default:
            fatalError("Unimplemented")
        }
    }
}

public extension MTLDepthStencilDescriptor {
    convenience init(depthCompareFunction: MTLCompareFunction, isDepthWriteEnabled: Bool = true) {
        self.init()
        self.depthCompareFunction = depthCompareFunction
        self.isDepthWriteEnabled = isDepthWriteEnabled
    }

    convenience init(isDepthWriteEnabled: Bool = true) {
        self.init()
        self.isDepthWriteEnabled = isDepthWriteEnabled
    }
}

public extension MTLCaptureManager {
    func with<R>(enabled: Bool = true, _ body: () throws -> R) throws -> R {
        guard enabled else {
            return try body()
        }
        let device = _MTLCreateSystemDefaultDevice()
        let captureScope = makeCaptureScope(device: device)
        let captureDescriptor = MTLCaptureDescriptor()
        captureDescriptor.captureObject = captureScope
        try startCapture(with: captureDescriptor)
        captureScope.begin()
        defer {
            captureScope.end()
        }
        return try body()
    }
}

public extension MTLCommandBuffer {
    func withDebugGroup<R>(enabled: Bool = true, _ label: String, _ body: () throws -> R) rethrows -> R {
        guard enabled else {
            return try body()
        }
        pushDebugGroup(label)
        defer {
            popDebugGroup()
        }
        return try body()
    }
}

public extension MTLRenderCommandEncoder {
    func withDebugGroup<R>(enabled: Bool = true, _ label: String, _ body: () throws -> R) rethrows -> R {
        guard enabled else {
            return try body()
        }
        pushDebugGroup(label)
        defer {
            popDebugGroup()
        }
        return try body()
    }
}

public extension MTLComputeCommandEncoder {
    func withDebugGroup<R>(enabled: Bool = true, _ label: String, _ body: () throws -> R) rethrows -> R {
        guard enabled else {
            return try body()
        }
        pushDebugGroup(label)
        defer {
            popDebugGroup()
        }
        return try body()
    }
}

public extension MTLBlitCommandEncoder {
    func withDebugGroup<R>(enabled: Bool = true, label: String, _ body: () throws -> R) rethrows -> R {
        guard enabled else {
            return try body()
        }
        pushDebugGroup(label)
        defer {
            popDebugGroup()
        }
        return try body()
    }
}

public enum MTLCommandQueueCompletion {
    case none
    case commit
    case commitAndWaitUntilCompleted
}

public extension MTLCommandQueue {
    func labeled(_ label: String) -> Self {
        self.label = label
        return self
    }
}

public extension MTLCommandBuffer {
    func labeled(_ label: String) -> Self {
        self.label = label
        return self
    }
}

public extension MTLRenderCommandEncoder {
    func labeled(_ label: String) -> Self {
        self.label = label
        return self
    }
}

public extension MTLTexture {
    func labeled(_ label: String) -> Self {
        self.label = label
        return self
    }
}

public extension MTLBuffer {
    func labeled(_ label: String) -> Self {
        self.label = label
        return self
    }
}

public extension MTLRenderCommandEncoder {
    func setVertexBuffers(of mesh: MTKMesh) {
        for (index, vertexBuffer) in mesh.vertexBuffers.enumerated() {
            setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: index)
        }
    }

    func draw(_ mesh: MTKMesh) {
        for submesh in mesh.submeshes {
            draw(submesh)
        }
    }

    func draw(_ submesh: MTKSubmesh) {
        drawIndexedPrimitives(type: submesh.primitiveType, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer.buffer, indexBufferOffset: submesh.indexBuffer.offset)
    }

    func draw(_ mesh: MTKMesh, instanceCount: Int) {
        for submesh in mesh.submeshes {
            draw(submesh, instanceCount: instanceCount)
        }
    }

    func draw(_ submesh: MTKSubmesh, instanceCount: Int) {
        drawIndexedPrimitives(type: submesh.primitiveType, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer.buffer, indexBufferOffset: submesh.indexBuffer.offset, instanceCount: instanceCount)
    }
}

public extension MTLVertexDescriptor {
    convenience init(_ vertexDescriptor: MDLVertexDescriptor) {
        self.init()
        // swiftlint:disable:next force_cast
        for (index, attribute) in vertexDescriptor.attributes.map({ $0 as! MDLVertexAttribute }).enumerated() {
            self.attributes[index].format = MTLVertexFormat(attribute.format)
            self.attributes[index].offset = attribute.offset
            self.attributes[index].bufferIndex = attribute.bufferIndex
        }
        // swiftlint:disable:next force_cast
        for (index, layout) in vertexDescriptor.layouts.map({ $0 as! MDLVertexBufferLayout }).enumerated() {
            self.layouts[index].stride = layout.stride
        }
    }
}

public extension MTLVertexFormat {
    // swiftlint:disable:next function_body_length cyclomatic_complexity
    init(_ dataType: MDLVertexFormat) {
        switch dataType {
        case .invalid:
            self = .invalid

        case .uChar:
            self = .uchar

        case .uChar2:
            self = .uchar2

        case .uChar3:
            self = .uchar3

        case .uChar4:
            self = .uchar4

        case .char:
            self = .char

        case .char2:
            self = .char2

        case .char3:
            self = .char3

        case .char4:
            self = .char4

        case .uCharNormalized:
            self = .ucharNormalized

        case .uChar2Normalized:
            self = .uchar2Normalized

        case .uChar3Normalized:
            self = .uchar3Normalized

        case .uChar4Normalized:
            self = .uchar4Normalized

        case .charNormalized:
            self = .charNormalized

        case .char2Normalized:
            self = .char2Normalized

        case .char3Normalized:
            self = .char3Normalized

        case .char4Normalized:
            self = .char4Normalized

        case .uShort:
            self = .ushort

        case .uShort2:
            self = .ushort2

        case .uShort3:
            self = .ushort3

        case .uShort4:
            self = .ushort4

        case .short:
            self = .short

        case .short2:
            self = .short2

        case .short3:
            self = .short3

        case .short4:
            self = .short4

        case .uShortNormalized:
            self = .ushortNormalized

        case .uShort2Normalized:
            self = .ushort2Normalized

        case .uShort3Normalized:
            self = .ushort3Normalized

        case .uShort4Normalized:
            self = .ushort4Normalized

        case .shortNormalized:
            self = .shortNormalized

        case .short2Normalized:
            self = .short2Normalized

        case .short3Normalized:
            self = .short3Normalized

        case .short4Normalized:
            self = .short4Normalized

        case .uInt:
            self = .uint

        case .uInt2:
            self = .uint2

        case .uInt3:
            self = .uint3

        case .uInt4:
            self = .uint4

        case .int:
            self = .int

        case .int2:
            self = .int2

        case .int3:
            self = .int3

        case .int4:
            self = .int4

        case .half:
            self = .half

        case .half2:
            self = .half2

        case .half3:
            self = .half3

        case .half4:
            self = .half4

        case .float:
            self = .float

        case .float2:
            self = .float2

        case .float3:
            self = .float3

        case .float4:
            self = .float4

        case .int1010102Normalized:
            self = .int1010102Normalized

        case .uInt1010102Normalized:
            self = .uint1010102Normalized

        default:
            fatalError("Unimplemented MDLVertexFormat(\(dataType.rawValue))")
        }
    }
}

public extension MTLFunction {
    func inferredVertexDescriptor() throws -> MTLVertexDescriptor {
        guard let vertexAttributes else {
            throw UltraviolenceError.generic("Function has no vertex attributes.")
        }
        let vertexDescriptor = MTLVertexDescriptor()
        for attribute in vertexAttributes {
            switch attribute.attributeType {
            case .float:
                vertexDescriptor.attributes[attribute.attributeIndex].format = .float
                vertexDescriptor.layouts[attribute.attributeIndex].stride = MemoryLayout<Float>.stride
            case .float2:
                vertexDescriptor.attributes[attribute.attributeIndex].format = .float2
                vertexDescriptor.layouts[attribute.attributeIndex].stride = MemoryLayout<SIMD2<Float>>.stride
            case .float3:
                vertexDescriptor.attributes[attribute.attributeIndex].format = .float3
                vertexDescriptor.layouts[attribute.attributeIndex].stride = MemoryLayout<Float>.stride * 3 // NOTE: We use the packed size here.
            case .float4:
                vertexDescriptor.attributes[attribute.attributeIndex].format = .float4
                vertexDescriptor.layouts[attribute.attributeIndex].stride = MemoryLayout<SIMD4<Float>>.stride
            case .half:
                vertexDescriptor.attributes[attribute.attributeIndex].format = .half
                vertexDescriptor.layouts[attribute.attributeIndex].stride = MemoryLayout<UInt16>.stride
            case .half2:
                vertexDescriptor.attributes[attribute.attributeIndex].format = .half2
                vertexDescriptor.layouts[attribute.attributeIndex].stride = MemoryLayout<SIMD2<UInt16>>.stride
            case .half3:
                vertexDescriptor.attributes[attribute.attributeIndex].format = .half3
                vertexDescriptor.layouts[attribute.attributeIndex].stride = MemoryLayout<UInt16>.stride * 3 // NOTE: We use the packed size here.
            case .half4:
                vertexDescriptor.attributes[attribute.attributeIndex].format = .half4
                vertexDescriptor.layouts[attribute.attributeIndex].stride = MemoryLayout<SIMD4<UInt16>>.stride
            case .int:
                vertexDescriptor.attributes[attribute.attributeIndex].format = .int
                vertexDescriptor.layouts[attribute.attributeIndex].stride = MemoryLayout<Int32>.stride
            case .int2:
                vertexDescriptor.attributes[attribute.attributeIndex].format = .int2
                vertexDescriptor.layouts[attribute.attributeIndex].stride = MemoryLayout<SIMD2<Int32>>.stride
            case .int3:
                vertexDescriptor.attributes[attribute.attributeIndex].format = .int3
                vertexDescriptor.layouts[attribute.attributeIndex].stride = MemoryLayout<Int32>.stride * 3 // NOTE: We use the packed size here.
            case .int4:
                vertexDescriptor.attributes[attribute.attributeIndex].format = .int4
                vertexDescriptor.layouts[attribute.attributeIndex].stride = MemoryLayout<SIMD4<Int32>>.stride
            case .uint:
                vertexDescriptor.attributes[attribute.attributeIndex].format = .uint
                vertexDescriptor.layouts[attribute.attributeIndex].stride = MemoryLayout<UInt32>.stride
            case .uint2:
                vertexDescriptor.attributes[attribute.attributeIndex].format = .uint2
                vertexDescriptor.layouts[attribute.attributeIndex].stride = MemoryLayout<SIMD2<UInt32>>.stride
            case .uint3:
                vertexDescriptor.attributes[attribute.attributeIndex].format = .uint3
                vertexDescriptor.layouts[attribute.attributeIndex].stride = MemoryLayout<UInt32>.stride * 3 // NOTE: We use the packed size here.
            case .uint4:
                vertexDescriptor.attributes[attribute.attributeIndex].format = .uint4
                vertexDescriptor.layouts[attribute.attributeIndex].stride = MemoryLayout<SIMD4<UInt32>>.stride
            case .short:
                vertexDescriptor.attributes[attribute.attributeIndex].format = .short
                vertexDescriptor.layouts[attribute.attributeIndex].stride = MemoryLayout<Int16>.stride
            case .short2:
                vertexDescriptor.attributes[attribute.attributeIndex].format = .short2
                vertexDescriptor.layouts[attribute.attributeIndex].stride = MemoryLayout<SIMD2<Int16>>.stride
            case .short3:
                vertexDescriptor.attributes[attribute.attributeIndex].format = .short3
                vertexDescriptor.layouts[attribute.attributeIndex].stride = MemoryLayout<Int16>.stride * 3 // NOTE: We use the packed size here.
            case .short4:
                vertexDescriptor.attributes[attribute.attributeIndex].format = .short4
                vertexDescriptor.layouts[attribute.attributeIndex].stride = MemoryLayout<SIMD4<Int16>>.stride
            case .ushort:
                vertexDescriptor.attributes[attribute.attributeIndex].format = .ushort
                vertexDescriptor.layouts[attribute.attributeIndex].stride = MemoryLayout<UInt16>.stride
            case .ushort2:
                vertexDescriptor.attributes[attribute.attributeIndex].format = .ushort2
                vertexDescriptor.layouts[attribute.attributeIndex].stride = MemoryLayout<SIMD2<UInt16>>.stride
            case .ushort3:
                vertexDescriptor.attributes[attribute.attributeIndex].format = .ushort3
                vertexDescriptor.layouts[attribute.attributeIndex].stride = MemoryLayout<UInt16>.stride * 3 // NOTE: We use the packed size here.
            case .ushort4:
                vertexDescriptor.attributes[attribute.attributeIndex].format = .ushort4
                vertexDescriptor.layouts[attribute.attributeIndex].stride = MemoryLayout<SIMD4<UInt16>>.stride
            case .char:
                vertexDescriptor.attributes[attribute.attributeIndex].format = .char
                vertexDescriptor.layouts[attribute.attributeIndex].stride = MemoryLayout<Int8>.stride
            case .char2:
                vertexDescriptor.attributes[attribute.attributeIndex].format = .char2
                vertexDescriptor.layouts[attribute.attributeIndex].stride = MemoryLayout<SIMD2<Int8>>.stride
            case .char3:
                vertexDescriptor.attributes[attribute.attributeIndex].format = .char3
                vertexDescriptor.layouts[attribute.attributeIndex].stride = MemoryLayout<Int8>.stride * 3 // NOTE: We use the packed size here.
            case .char4:
                vertexDescriptor.attributes[attribute.attributeIndex].format = .char4
                vertexDescriptor.layouts[attribute.attributeIndex].stride = MemoryLayout<SIMD4<Int8>>.stride
            case .uchar:
                vertexDescriptor.attributes[attribute.attributeIndex].format = .uchar
                vertexDescriptor.layouts[attribute.attributeIndex].stride = MemoryLayout<UInt8>.stride
            case .uchar2:
                vertexDescriptor.attributes[attribute.attributeIndex].format = .uchar2
                vertexDescriptor.layouts[attribute.attributeIndex].stride = MemoryLayout<SIMD2<UInt8>>.stride
            case .uchar3:
                vertexDescriptor.attributes[attribute.attributeIndex].format = .uchar3
                vertexDescriptor.layouts[attribute.attributeIndex].stride = MemoryLayout<UInt8>.stride * 3 // NOTE: We use the packed size here.
            case .uchar4:
                vertexDescriptor.attributes[attribute.attributeIndex].format = .uchar4
                vertexDescriptor.layouts[attribute.attributeIndex].stride = MemoryLayout<SIMD4<UInt8>>.stride
            default:
                // TODO: #181 Flesh this out.
                fatalError("Unimplemented: \(attribute.attributeType)")
            }
            vertexDescriptor.attributes[attribute.attributeIndex].bufferIndex = attribute.attributeIndex
        }
        return vertexDescriptor
    }
}

public extension MTLRenderCommandEncoder {
    func setVertexUnsafeBytes(of value: [some Any], index: Int) {
        precondition(index >= 0)
        value.withUnsafeBytes { buffer in
            let baseAddress = buffer.baseAddress.orFatalError(.resourceCreationFailure("No base address."))
            setVertexBytes(baseAddress, length: buffer.count, index: index)
        }
    }

    func setVertexUnsafeBytes(of value: some Any, index: Int) {
        precondition(index >= 0)
        assert(isPOD(value))
        withUnsafeBytes(of: value) { buffer in
            let baseAddress = buffer.baseAddress.orFatalError(.resourceCreationFailure("No base address."))
            setVertexBytes(baseAddress, length: buffer.count, index: index)
        }
    }
}

public extension MTLRenderCommandEncoder {
    func setFragmentUnsafeBytes(of value: [some Any], index: Int) {
        precondition(index >= 0)
        value.withUnsafeBytes { buffer in
            let baseAddress = buffer.baseAddress.orFatalError(.resourceCreationFailure("No base address."))
            setFragmentBytes(baseAddress, length: buffer.count, index: index)
        }
    }

    func setFragmentUnsafeBytes(of value: some Any, index: Int) {
        precondition(index >= 0)
        assert(isPOD(value))
        withUnsafeBytes(of: value) { buffer in
            let baseAddress = buffer.baseAddress.orFatalError(.resourceCreationFailure("No base address."))
            setFragmentBytes(baseAddress, length: buffer.count, index: index)
        }
    }
}

public extension MTLRenderCommandEncoder {
    func setUnsafeBytes(of value: [some Any], index: Int, functionType: MTLFunctionType) {
        precondition(index >= 0)
        switch functionType {
        case .vertex:
            setVertexUnsafeBytes(of: value, index: index)

        case .fragment:
            setFragmentUnsafeBytes(of: value, index: index)

        default:
            fatalError("Unimplemented")
        }
    }

    func setUnsafeBytes(of value: some Any, index: Int, functionType: MTLFunctionType) {
        precondition(index >= 0)
        assert(isPOD(value))
        switch functionType {
        case .vertex:
            setVertexUnsafeBytes(of: value, index: index)

        case .fragment:
            setFragmentUnsafeBytes(of: value, index: index)

        default:
            fatalError("Unimplemented")
        }
    }

    func setBuffer(_ buffer: MTLBuffer?, offset: Int, index: Int, functionType: MTLFunctionType) {
        switch functionType {
        case .vertex:
            setVertexBuffer(buffer, offset: offset, index: index)

        case .fragment:
            setFragmentBuffer(buffer, offset: offset, index: index)

        default:
            fatalError("Unimplemented")
        }
    }

    func setTexture(_ texture: MTLTexture?, index: Int, functionType: MTLFunctionType) {
        switch functionType {
        case .vertex:
            setVertexTexture(texture, index: index)

        case .fragment:
            setFragmentTexture(texture, index: index)

        default:
            fatalError("Unimplemented")
        }
    }

    func setSamplerState(_ sampler: MTLSamplerState?, index: Int, functionType: MTLFunctionType) {
        switch functionType {
        case .vertex:
            setVertexSamplerState(sampler, index: index)

        case .fragment:
            setFragmentSamplerState(sampler, index: index)

        default:
            fatalError("Unimplemented")
        }
    }
}

public extension MTLComputeCommandEncoder {
    func setUnsafeBytes(of value: [some Any], index: Int) {
        precondition(index >= 0)
        value.withUnsafeBytes { buffer in
            let baseAddress = buffer.baseAddress.orFatalError(.resourceCreationFailure("No base address."))
            setBytes(baseAddress, length: buffer.count, index: index)
        }
    }

    func setUnsafeBytes(of value: some Any, index: Int) {
        precondition(index >= 0)
        assert(isPOD(value))
        withUnsafeBytes(of: value) { buffer in
            let baseAddress = buffer.baseAddress.orFatalError(.resourceCreationFailure("No base address."))
            setBytes(baseAddress, length: buffer.count, index: index)
        }
    }
}

public extension MTLDevice {
    func makeBuffer<T>(unsafeBytesOf value: T, options: MTLResourceOptions = []) throws -> MTLBuffer {
        precondition(isPOD(value))
        return try withUnsafeBytes(of: value) { buffer in
            let baseAddress = buffer.baseAddress.orFatalError(.resourceCreationFailure("No base address."))
            return try makeBuffer(bytes: baseAddress, length: buffer.count, options: options).orThrow(.resourceCreationFailure("Failed to create buffer from bytes"))
        }
    }

    func makeBuffer<T>(unsafeBytesOf value: [T], options: MTLResourceOptions = []) throws -> MTLBuffer {
        precondition(isPODArray(value))
        return try value.withUnsafeBytes { buffer in
            let baseAddress = buffer.baseAddress.orFatalError(.resourceCreationFailure("No base address."))
            return try makeBuffer(bytes: baseAddress, length: buffer.count, options: options).orThrow(.resourceCreationFailure("Failed to create buffer from array bytes"))
        }
    }

    func makeBuffer<C>(collection: C, options: MTLResourceOptions) throws -> MTLBuffer where C: Collection {
        assert(isPOD(C.Element.self))
        let buffer = try collection.withContiguousStorageIfAvailable { buffer in
            let raw = UnsafeRawBufferPointer(buffer)
            let baseAddress = raw.baseAddress.orFatalError(.resourceCreationFailure("No base address."))
            guard let buffer = makeBuffer(bytes: baseAddress, length: raw.count, options: options) else {
                throw UltraviolenceError.resourceCreationFailure("MTLDevice.makeBuffer failed.")
            }
            return buffer
        }
        guard let buffer else {
            fatalError("No contiguous storage available.")
        }
        return buffer
    }
}

public extension MTLBuffer {
    func contentsBuffer() -> UnsafeRawBufferPointer {
        UnsafeRawBufferPointer(start: contents(), count: length)
    }

    func contents<T>() -> UnsafeBufferPointer<T> {
        contentsBuffer().bindMemory(to: T.self)
    }
}

public extension MTLCommandBufferDescriptor {
    func addDefaultLogging() throws {
        let logStateDescriptor = MTLLogStateDescriptor()
        logStateDescriptor.bufferSize = 16 * 1_024
        let device = _MTLCreateSystemDefaultDevice()
        let logState = try device.makeLogState(descriptor: logStateDescriptor)
        logState.addLogHandler { _, _, _, message in
            logger?.log("\(message)")
        }
        self.logState = logState
    }
}

public extension SIMD2<Float> {
    init(_ size: CGSize) {
        self.init(Float(size.width), Float(size.height))
    }
}

public func _MTLCreateSystemDefaultDevice() -> MTLDevice {
    MTLCreateSystemDefaultDevice().orFatalError(.unexpectedError(.resourceCreationFailure("Could not create system default device.")))
}

public extension MTLDevice {
    func _makeCommandQueue() throws -> MTLCommandQueue {
        try makeCommandQueue().orThrow(.resourceCreationFailure("Could not create command queue."))
    }

    func _makeSamplerState(descriptor: MTLSamplerDescriptor) throws -> MTLSamplerState {
        try makeSamplerState(descriptor: descriptor).orThrow(.resourceCreationFailure("Could not create sampler state."))
    }

    func _makeTexture(descriptor: MTLTextureDescriptor) throws -> MTLTexture {
        try makeTexture(descriptor: descriptor).orThrow(.resourceCreationFailure("Could not create texture."))
    }
}

public extension MTLCommandQueue {
    func _makeCommandBuffer() throws -> MTLCommandBuffer {
        try makeCommandBuffer().orThrow(.resourceCreationFailure("Could not create command buffer."))
    }

    func _makeCommandBuffer(descriptor: MTLCommandBufferDescriptor) throws -> MTLCommandBuffer {
        try makeCommandBuffer(descriptor: descriptor).orThrow(.resourceCreationFailure("Could not create command buffer."))
    }
}

public extension MTLCommandBuffer {
    func _makeBlitCommandEncoder() throws -> MTLBlitCommandEncoder {
        logger?.verbose?.info("Creating blit command encoder")
        return try makeBlitCommandEncoder().orThrow(.resourceCreationFailure("Could not create blit command encoder."))
    }

    func _makeComputeCommandEncoder() throws -> MTLComputeCommandEncoder {
        logger?.verbose?.info("Creating compute command encoder")
        return try makeComputeCommandEncoder().orThrow(.resourceCreationFailure("Could not create compute command encoder."))
    }

    func _makeRenderCommandEncoder(descriptor: MTLRenderPassDescriptor) throws -> MTLRenderCommandEncoder {
        logger?.verbose?.info("Creating render command encoder with descriptor: \(descriptor.debugDescription)")
        return try makeRenderCommandEncoder(descriptor: descriptor).orThrow(.resourceCreationFailure("Could not create render command encoder."))
    }
}

public extension MTLDevice {
    // Deal with your own endian problems.
    func makeTexture<T>(descriptor: MTLTextureDescriptor, repeating value: T) throws -> MTLTexture {
        assert(isPOD(value))
        let numPixels = descriptor.width * descriptor.height
        let values = [T](repeating: value, count: numPixels)
        let texture = try _makeTexture(descriptor: descriptor)
        values.withUnsafeBufferPointer { buffer in
            let buffer = UnsafeRawBufferPointer(buffer)
            let baseAddress = buffer.baseAddress.orFatalError()
            texture.replace(region: MTLRegionMake2D(0, 0, descriptor.width, descriptor.height), mipmapLevel: 0, withBytes: baseAddress, bytesPerRow: descriptor.width * MemoryLayout<T>.stride)
        }
        return texture
    }

    func make1PixelTexture(color: SIMD4<Float>) throws -> MTLTexture {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: 1, height: 1, mipmapped: false)
        descriptor.usage = [.shaderRead, .shaderWrite, .renderTarget] // TODO: #120 Too much
        descriptor.storageMode = .shared
        let value = SIMD4<UInt8>(color * 255.0)
        return try makeTexture(descriptor: descriptor, repeating: value)
    }
}

public extension MTLTexture {
    func toCGImage() throws -> CGImage {
        // TODO: #121 Hack
        assert(self.pixelFormat == .bgra8Unorm || self.pixelFormat == .bgra8Unorm_srgb)
        var bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
        bitmapInfo.insert(.byteOrder32Little)
        let context = try CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: bitmapInfo.rawValue).orThrow(.resourceCreationFailure("Failed to create context."))
        let data = try context.data.orThrow(.resourceCreationFailure("Failed to get context data."))
        getBytes(data, bytesPerRow: width * 4, from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)
        return try context.makeImage().orThrow(.resourceCreationFailure("Failed to create image."))
    }

    func toImage() throws -> Image {
        #if canImport(AppKit)
        let nsImage = NSImage(cgImage: try toCGImage(), size: CGSize(width: width, height: height))
        return Image(nsImage: nsImage)
        #elseif canImport(UIKit)
        let cgImage = try toCGImage()
        let uiImage = UIImage(cgImage: cgImage)
        return Image(uiImage: uiImage)
        #endif
    }

    func write(to url: URL) throws {
        let image = try toCGImage()
        // TODO: #122 We're ignoring the file extension.
        let destination = try CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil).orThrow(.resourceCreationFailure("Failed to create image destination"))
        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)
    }
}

public extension MTLStencilDescriptor {
    convenience init(compareFunction: MTLCompareFunction = .always, stencilFailureOperation: MTLStencilOperation = .keep, depthFailureOperation: MTLStencilOperation = .keep, stencilPassDepthPassOperation: MTLStencilOperation = .keep, readMask: UInt32 = 0xffffffff, writeMask: UInt32 = 0xffffffff) {
        self.init()
        self.stencilCompareFunction = compareFunction
        self.stencilFailureOperation = stencilFailureOperation
        self.depthFailureOperation = depthFailureOperation
        self.depthStencilPassOperation = stencilPassDepthPassOperation
        self.readMask = readMask
        self.writeMask = writeMask
    }
}

public extension MTLDepthStencilDescriptor {
    convenience init(depthCompareFunction: MTLCompareFunction = .less, isDepthWriteEnabled: Bool = true, frontFaceStencil: MTLStencilDescriptor? = nil, backFaceStencil: MTLStencilDescriptor? = nil, label: String? = nil) {
        self.init()
        self.depthCompareFunction = depthCompareFunction
        self.isDepthWriteEnabled = isDepthWriteEnabled
        if let frontFaceStencil {
            self.frontFaceStencil = frontFaceStencil
        }
        if let backFaceStencil {
            self.backFaceStencil = backFaceStencil
        }
        if let label {
            self.label = label
        }
    }
}

public extension MTLSamplerDescriptor {
    // swiftlint:disable discouraged_optional_boolean
    // swiftlint:disable:next cyclomatic_complexity
    convenience init(minFilter: MTLSamplerMinMagFilter? = nil, magFilter: MTLSamplerMinMagFilter? = nil, mipFilter: MTLSamplerMipFilter? = nil, maxAnisotropy: Int? = nil, sAddressMode: MTLSamplerAddressMode? = nil, tAddressMode: MTLSamplerAddressMode? = nil, rAddressMode: MTLSamplerAddressMode? = nil, borderColor: MTLSamplerBorderColor? = nil, normalizedCoordinates: Bool? = nil, lodMinClamp: Float? = nil, lodMaxClamp: Float? = nil, lodAverage: Bool? = nil, compareFunction: MTLCompareFunction? = nil, supportArgumentBuffers: Bool? = nil, label: String? = nil) {
        // swiftlint:enable discouraged_optional_boolean
        self.init()
        if let minFilter {
            self.minFilter = minFilter
        }
        if let magFilter {
            self.magFilter = magFilter
        }
        if let mipFilter {
            self.mipFilter = mipFilter
        }
        if let maxAnisotropy {
            self.maxAnisotropy = maxAnisotropy
        }
        if let sAddressMode {
            self.sAddressMode = sAddressMode
        }
        if let tAddressMode {
            self.tAddressMode = tAddressMode
        }
        if let rAddressMode {
            self.rAddressMode = rAddressMode
        }
        if let borderColor {
            self.borderColor = borderColor
        }
        if let normalizedCoordinates {
            self.normalizedCoordinates = normalizedCoordinates
        }
        if let lodMinClamp {
            self.lodMinClamp = lodMinClamp
        }
        if let lodMaxClamp {
            self.lodMaxClamp = lodMaxClamp
        }
        if let lodAverage {
            self.lodAverage = lodAverage
        }
        if let compareFunction {
            self.compareFunction = compareFunction
        }
        if let supportArgumentBuffers {
            self.supportArgumentBuffers = supportArgumentBuffers
        }
        if let label {
            self.label = label
        }
    }
}

public extension MTKMesh {
    func relabeled(_ label: String) -> MTKMesh {
        for (index, buffer) in vertexBuffers.enumerated() {
            buffer.buffer.label = "\(label)-vertexBuffer-\(index)"
        }
        for (index, submesh) in submeshes.enumerated() {
            submesh.indexBuffer.buffer.label = "\(label)-submesh-indexBuffer-\(index)"
        }
        return self
    }
}

public extension MTLBuffer {
    func gpuAddressAsUnsafeMutablePointer<T>(type: T.Type) -> UnsafeMutablePointer<T>? {
        precondition(MemoryLayout<Int>.stride == MemoryLayout<UInt64>.stride)
        let bits = Int(Int64(bitPattern: gpuAddress))
        return UnsafeMutablePointer<T>(bitPattern: bits)
    }
}
