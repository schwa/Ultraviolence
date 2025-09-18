import MetalKit

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

public extension MTKMesh {
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

public extension MTKMesh {
    struct Options: OptionSet, Sendable {
        public let rawValue: Int

        public static let generateTextureCoordinatesIfMissing = Self(rawValue: 1 << 0)
        public static let generateTangentBasis = Self(rawValue: 1 << 1)
        public static let useSimpleTextureCoordinates = Self(rawValue: 1 << 2)

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }

    convenience init(name: String, bundle: Bundle) throws {
        let device = _MTLCreateSystemDefaultDevice()
        let url = bundle.url(forResource: name, withExtension: "obj")
        let vertexDescriptor = MDLVertexDescriptor()
        vertexDescriptor.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition, format: .float3, offset: 0, bufferIndex: 0)
        vertexDescriptor.attributes[1] = MDLVertexAttribute(name: MDLVertexAttributeNormal, format: .float3, offset: 0, bufferIndex: 0)
        vertexDescriptor.attributes[2] = MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate, format: .float2, offset: 0, bufferIndex: 0)
        vertexDescriptor.setPackedOffsets()
        vertexDescriptor.setPackedStrides()
        let mdlAsset = MDLAsset(url: url, vertexDescriptor: vertexDescriptor, bufferAllocator: MTKMeshBufferAllocator(device: device))
        let mdlMesh = (mdlAsset.object(at: 0) as? MDLMesh).orFatalError(.resourceCreationFailure("Failed to load teapot mesh."))
        try self.init(mesh: mdlMesh, device: device)
    }

    convenience init(name: String, bundle: Bundle, device: MTLDevice? = nil, allocator: MTKMeshBufferAllocator? = nil, options: Options) throws {
        guard let url = bundle.url(forResource: name, withExtension: "obj") else {
            fatalError()
        }
        try self.init(url: url, device: device, allocator: allocator, options: options)
    }

    convenience init(url: URL, device: MTLDevice? = nil, allocator: MTKMeshBufferAllocator? = nil, options: Options) throws {
        let device = device ?? _MTLCreateSystemDefaultDevice()
        let allocator = allocator ?? MTKMeshBufferAllocator(device: device)
        let mdlAsset = MDLAsset(url: url, vertexDescriptor: nil, bufferAllocator: allocator)
        let mdlMesh = (mdlAsset.object(at: 0) as? MDLMesh).orFatalError(.resourceCreationFailure("Failed to load teapot mesh."))
        try self.init(mdlMesh: mdlMesh, device: device, options: options)
    }

    convenience init(mdlMesh: MDLMesh, device: MTLDevice, options: Options) throws {
        // Check what attributes the original model has BEFORE we modify the descriptor
        let hasOriginalTexCoords = mdlMesh.vertexAttributeData(forAttributeNamed: MDLVertexAttributeTextureCoordinate, as: .float2) != nil
        let hasOriginalTangent = mdlMesh.vertexAttributeData(forAttributeNamed: MDLVertexAttributeTangent, as: .float3) != nil
        let hasOriginalBitangent = mdlMesh.vertexAttributeData(forAttributeNamed: MDLVertexAttributeBitangent, as: .float3) != nil
        let hasOriginalTangentBasis = hasOriginalTangent && hasOriginalBitangent

        // Ensure normals exist
        if mdlMesh.vertexAttributeData(forAttributeNamed: MDLVertexAttributeNormal, as: .float3) == nil {
            mdlMesh.addNormals(withAttributeNamed: MDLVertexAttributeNormal, creaseThreshold: 0.0)
        }

        // Generate texture coordinates if missing
        if !hasOriginalTexCoords, options.contains(.generateTextureCoordinatesIfMissing) {
            if options.contains(.useSimpleTextureCoordinates) {
                // Use simple spherical mapping (fast, works for any mesh)
                logger?.info("Creating spherical texture coordinates.")
                // ModelIO doesn't have a built-in spherical mapping, so we'll create a simple planar projection
                // This is fast and doesn't hang on complex meshes
                if let positionAttribute = mdlMesh.vertexAttributeData(forAttributeNamed: MDLVertexAttributePosition, as: .float3) {
                    let vertexCount = mdlMesh.vertexCount
                    var texCoords = [SIMD2<Float>]()
                    texCoords.reserveCapacity(vertexCount)

                    // Get bounding box for normalization
                    let bounds = mdlMesh.boundingBox
                    let size = bounds.maxBounds - bounds.minBounds
                    let center = (bounds.minBounds + bounds.maxBounds) * 0.5
                    let maxDim = max(size.x, max(size.y, size.z))

                    // Create spherical coordinates
                    let positionData = positionAttribute.dataStart
                    let positionStride = positionAttribute.stride

                    for i in 0..<vertexCount {
                        let positionPtr = positionData.advanced(by: i * positionStride).assumingMemoryBound(to: Float.self)
                        let pos = SIMD3<Float>(positionPtr[0], positionPtr[1], positionPtr[2])

                        // Normalize position relative to center
                        let relative = (pos - center) / maxDim

                        // Convert to spherical coordinates
                        let theta = atan2(relative.z, relative.x)
                        let phi = asin(max(-1, min(1, relative.y)))

                        // Map to UV space [0, 1]
                        let u = (theta + .pi) / (2 * .pi)
                        let v = (phi + .pi / 2) / .pi

                        texCoords.append(SIMD2<Float>(u, v))
                    }
                    mdlMesh.addAttribute(withName: MDLVertexAttributeTextureCoordinate, format: .float2)
                }
            } else {
                // Use ModelIO's automatic unwrapping (can be slow/hang on complex meshes)
                logger?.info("Creating unwrapped texture coordinates.")
                mdlMesh.addUnwrappedTextureCoordinates(forAttributeNamed: MDLVertexAttributeTextureCoordinate)
            }
        }

        // Check if we have texture coordinates now (either original or generated)
        let hasTextureCoordinates = mdlMesh.vertexAttributeData(forAttributeNamed: MDLVertexAttributeTextureCoordinate, as: .float2) != nil

        // Generate tangent basis if requested, doesn't exist, and texture coordinates are available
        if options.contains(.generateTangentBasis), !hasOriginalTangentBasis, hasTextureCoordinates {
            mdlMesh.addTangentBasis(
                forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate,
                tangentAttributeNamed: MDLVertexAttributeTangent,
                bitangentAttributeNamed: MDLVertexAttributeBitangent
            )
        }

        // NOW create and apply our vertex descriptor to ensure all attributes are in buffer 0
        let vertexDescriptor = MDLVertexDescriptor()

        // Position at attribute 0
        vertexDescriptor.attributes[0] = MDLVertexAttribute(
            name: MDLVertexAttributePosition,
            format: .float3,
            offset: 0,
            bufferIndex: 0
        )

        // Normal at attribute 1
        vertexDescriptor.attributes[1] = MDLVertexAttribute(
            name: MDLVertexAttributeNormal,
            format: .float3,
            offset: 12,
            bufferIndex: 0
        )

        // Texture coordinate at attribute 2
        vertexDescriptor.attributes[2] = MDLVertexAttribute(
            name: MDLVertexAttributeTextureCoordinate,
            format: .float2,
            offset: 24,
            bufferIndex: 0
        )

        // Tangent at attribute 3
        vertexDescriptor.attributes[3] = MDLVertexAttribute(
            name: MDLVertexAttributeTangent,
            format: .float3,
            offset: 32,
            bufferIndex: 0
        )

        // Bitangent at attribute 4
        vertexDescriptor.attributes[4] = MDLVertexAttribute(
            name: MDLVertexAttributeBitangent,
            format: .float3,
            offset: 44,
            bufferIndex: 0
        )

        // Set the layout for buffer 0
        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: 56)

        // Apply our vertex descriptor to repack all attributes into buffer 0
        mdlMesh.vertexDescriptor = vertexDescriptor

        try self.init(mesh: mdlMesh, device: device)
    }
}
