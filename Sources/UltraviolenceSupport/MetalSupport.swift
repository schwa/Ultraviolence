// swiftlint:disable file_length

import Metal
import MetalKit
import ModelIO

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
        let device = try MTLCreateSystemDefaultDevice().orThrow(.resourceCreationFailure)
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

public extension MTLRenderCommandEncoder {
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

public extension MTLComputeCommandEncoder {
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

public extension MTLDevice {
    func withCommandQueue<R>(label: String? = nil, _ body: (MTLCommandQueue) throws -> R) throws -> R {
        let commandQueue = try makeCommandQueue().orThrow(.resourceCreationFailure)
        if let label {
            commandQueue.label = label
        }
        return try body(commandQueue)
    }
}

public enum MTLCommandQueueCompletion {
    case none
    case commit
    case commitAndWaitUntilCompleted
}

public extension MTLCommandQueue {
    func withCommandBuffer<R>(logState: MTLLogState? = nil, completion: MTLCommandQueueCompletion = .commit, label: String? = nil, debugGroup: String? = nil, _ body: (MTLCommandBuffer) throws -> R) throws -> R {
        let commandBufferDescriptor = MTLCommandBufferDescriptor()
        if let logState {
            commandBufferDescriptor.logState = logState
        }

        let commandBuffer = try makeCommandBuffer(descriptor: commandBufferDescriptor).orThrow(.resourceCreationFailure)
        if let debugGroup {
            commandBuffer.pushDebugGroup(debugGroup)
        }
        defer {
            switch completion {
            case .none:
                break
            case .commit:
                commandBuffer.commit()
            case .commitAndWaitUntilCompleted:
                commandBuffer.commit()
                commandBuffer.waitUntilCompleted()
            }
            if debugGroup != nil {
                commandBuffer.popDebugGroup()
            }
        }
        if let label {
            commandBuffer.label = label
        }
        return try body(commandBuffer)
    }
}

public extension MTLCommandBuffer {
    func withRenderCommandEncoder<R>(descriptor: MTLRenderPassDescriptor, label: String? = nil, debugGroup: String? = nil, _ body: (MTLRenderCommandEncoder) throws -> R) throws -> R {
        let encoder = try makeRenderCommandEncoder(descriptor: descriptor).orThrow(.resourceCreationFailure)
        if let debugGroup {
            encoder.pushDebugGroup(debugGroup)
        }
        defer {
            encoder.endEncoding()
            if debugGroup != nil {
                encoder.popDebugGroup()
            }
        }
        if let label {
            encoder.label = label
        }
        return try body(encoder)
    }
}

public extension MTLCommandBuffer {
    func withComputeCommandEncoder<R>(label: String? = nil, debugGroup: String? = nil, _ body: (MTLComputeCommandEncoder) throws -> R) throws -> R {
        let encoder = try makeComputeCommandEncoder().orThrow(.resourceCreationFailure)
        if let debugGroup {
            encoder.pushDebugGroup(debugGroup)
        }
        defer {
            encoder.endEncoding()
            if debugGroup != nil {
                encoder.popDebugGroup()
            }
        }
        if let label {
            encoder.label = label
        }
        return try body(encoder)
    }
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
    func draw(_ mesh: MTKMesh) {
        for (index, vertexBuffer) in mesh.vertexBuffers.enumerated() {
            setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: index)
        }

        for submesh in mesh.submeshes {
            draw(submesh)
        }
    }

    func draw(_ submesh: MTKSubmesh) {
        drawIndexedPrimitives(type: submesh.primitiveType, indexCount: submesh.indexCount, indexType: submesh.indexType, indexBuffer: submesh.indexBuffer.buffer, indexBufferOffset: submesh.indexBuffer.offset)
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
    var vertexDescriptor: MTLVertexDescriptor? {
        guard let vertexAttributes else {
            return nil
        }
        let vertexDescriptor = MTLVertexDescriptor()

        var totalStride: Int = 0
        for attribute in vertexAttributes {
            switch attribute.attributeType {
            case .float2:
                vertexDescriptor.attributes[attribute.attributeIndex].format = .float2
                vertexDescriptor.layouts[attribute.attributeIndex].stride = MemoryLayout<SIMD2<Float>>.stride
                totalStride += MemoryLayout<SIMD2<Float>>.stride
            default:
                // TODO: Flesh this out.
                fatalError("Unimplemented")
            }
        }
        vertexDescriptor.layouts[0].stride = totalStride
        return vertexDescriptor
    }
}

public extension MTLRenderCommandEncoder {
    func setVertexUnsafeBytes(of value: [some Any], index: Int) {
        precondition(index >= 0)
        value.withUnsafeBytes { buffer in
            setVertexBytes(buffer.baseAddress.orFatalError(.resourceCreationFailure), length: buffer.count, index: index)
        }
    }

    func setVertexUnsafeBytes(of value: some Any, index: Int) {
        precondition(index >= 0)
        assert(isPOD(value))
        withUnsafeBytes(of: value) { buffer in
            setVertexBytes(buffer.baseAddress.orFatalError(.resourceCreationFailure), length: buffer.count, index: index)
        }
    }
}

public extension MTLRenderCommandEncoder {
    func setFragmentUnsafeBytes(of value: [some Any], index: Int) {
        precondition(index >= 0)
        value.withUnsafeBytes { buffer in
            setFragmentBytes(buffer.baseAddress.orFatalError(.resourceCreationFailure), length: buffer.count, index: index)
        }
    }

    func setFragmentUnsafeBytes(of value: some Any, index: Int) {
        precondition(index >= 0)
        assert(isPOD(value))
        withUnsafeBytes(of: value) { buffer in
            setFragmentBytes(buffer.baseAddress.orFatalError(.resourceCreationFailure), length: buffer.count, index: index)
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

    func setBuffer(_ buffer: MTLBuffer, offset: Int, index: Int, functionType: MTLFunctionType) {
        switch functionType {
        case .vertex:
            setVertexBuffer(buffer, offset: offset, index: index)
        case .fragment:
            setFragmentBuffer(buffer, offset: offset, index: index)
        default:
            fatalError("Unimplemented")
        }
    }

    func setTexture(_ texture: MTLTexture, index: Int, functionType: MTLFunctionType) {
        switch functionType {
        case .vertex:
            setVertexTexture(texture, index: index)
        case .fragment:
            setFragmentTexture(texture, index: index)
        default:
            fatalError("Unimplemented")
        }
    }
}

public extension MTLComputeCommandEncoder {
    func setUnsafeBytes(of value: [some Any], index: Int) {
        precondition(index >= 0)
        value.withUnsafeBytes { buffer in
            setBytes(buffer.baseAddress.orFatalError(.resourceCreationFailure), length: buffer.count, index: index)
        }
    }

    func setUnsafeBytes(of value: some Any, index: Int) {
        precondition(index >= 0)
        assert(isPOD(value))
        withUnsafeBytes(of: value) { buffer in
            setBytes(buffer.baseAddress.orFatalError(.resourceCreationFailure), length: buffer.count, index: index)
        }
    }
}

// TODO: Move
public extension MTLDevice {
    func makeBuffer<C>(collection: C, options: MTLResourceOptions) throws -> MTLBuffer where C: Collection {
        assert(isPOD(C.Element.self))
        let buffer = try collection.withContiguousStorageIfAvailable { buffer in
            let raw = UnsafeRawBufferPointer(buffer)
            guard let buffer = makeBuffer(bytes: raw.baseAddress.orFatalError(), length: raw.count, options: options) else {
                throw UltraviolenceError.resourceCreationFailure
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
