internal import AsyncAlgorithms
import UltraviolenceGaussianSplatShaders
import Metal
internal import os
import simd
import UltraviolenceSupport

// TODO: #146 Dangerous `@unchecked Sendable` usage in SplatCloud.
public final class SplatCloud <Splat>: Equatable, @unchecked Sendable where Splat: SortableSplatProtocol {
    public private(set) var splats: TypedMTLBuffer<Splat>
    internal var indexedDistances: SplatIndices
    public var label: String?

    // MARK: -

    public init(splats: TypedMTLBuffer<Splat>, indexedDistances: SplatIndices) {
        self.splats = splats
        self.indexedDistances = indexedDistances
    }

    public convenience init(device: MTLDevice, splats: TypedMTLBuffer<Splat>, cameraMatrix: simd_float4x4, modelMatrix: simd_float4x4) throws {
        let indexedDistances = try CPUSplatRadixSorter.sort(device: device, splats: splats, camera: cameraMatrix, model: modelMatrix, reversed: false)
        self.init(splats: splats, indexedDistances: indexedDistances)
    }

    public convenience init(device: MTLDevice, splats: [Splat], cameraMatrix: simd_float4x4, modelMatrix: simd_float4x4) throws {
        let splats = try device.makeTypedBuffer(values: splats, options: [])
        try self.init(device: device, splats: splats, cameraMatrix: cameraMatrix, modelMatrix: modelMatrix)
    }

    // MARK: -

    public static func == (lhs: SplatCloud, rhs: SplatCloud) -> Bool {
        lhs.splats == rhs.splats && lhs.indexedDistances == rhs.indexedDistances
    }

    /// How many splats are currently in the splat cloud
    public var count: Int {
        splats.count
    }
}

// MARK: -

public struct SplatIndices: @unchecked Sendable, Equatable {
    var parameters: SortParameters
    var indices: TypedMTLBuffer<IndexedDistance>
}

// MARK: -

internal struct SortParameters: Sendable, Equatable {
    var time: TimeInterval
    var camera: simd_float4x4
    var model: simd_float4x4
    var reversed: Bool

    init(time: TimeInterval = Date.timeIntervalSinceReferenceDate, camera: simd_float4x4, model: simd_float4x4, reversed: Bool = false) {
        self.time = time
        self.camera = camera
        self.model = model
        self.reversed = reversed
    }
}
