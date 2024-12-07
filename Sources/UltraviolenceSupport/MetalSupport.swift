import Metal

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
