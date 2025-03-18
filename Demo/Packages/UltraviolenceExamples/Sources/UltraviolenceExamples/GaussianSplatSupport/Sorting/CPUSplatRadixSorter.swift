internal import AsyncAlgorithms
import GaussianSplatShaders
@preconcurrency import Metal
internal import os
import simd

private let signposter: OSSignposter? = .init(subsystem: "io.schwa.ultraviolence-examples", category: OSLog.Category.pointsOfInterest)

internal class CPUSplatRadixSorter <Splat> where Splat: SortableSplatProtocol {
    private var device: MTLDevice
    private var temporaryIndexedDistances: [IndexedDistance]
    private var capacity: Int
    private var signpost = signposter?.makeSignpostID()

    internal init(device: MTLDevice, capacity: Int) {
        self.device = device
        self.capacity = capacity
        releaseAssert(capacity > 0, "You shouldn't be creating a sorter with a capacity of zero.")
        temporaryIndexedDistances = .init(repeating: .init(), count: capacity)
    }

    internal func sort(splats: TypedMTLBuffer<Splat>, camera: simd_float4x4, model: simd_float4x4, reversed: Bool = false) throws -> TypedMTLBuffer<IndexedDistance> {
        try signposter.withIntervalSignpost("CPUSplatRadixSorter.sort().make_buffers", id: signpost) {
            var currentIndexedDistances = try signposter.withIntervalSignpost("CPUSplatRadixSorter.sort()", id: signpost) {
                try device.makeTypedBuffer(element: IndexedDistance.self, capacity: capacity, options: []).labeled("\(splats.unsafeMTLBuffer.label ?? "splats")-indexed_distances-\(Date.now.iso8601)")
            }
            signposter.withIntervalSignpost("CPUSplatRadixSorter.cpuRadixSort()", id: signpost) {
                cpuRadixSort(splats: splats, indexedDistances: &currentIndexedDistances, temporaryIndexedDistances: &temporaryIndexedDistances, camera: camera, model: model, reversed: reversed)
            }
            return currentIndexedDistances
        }
    }
}

extension Date {
    var iso8601: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions.insert(.withFractionalSeconds)
        formatter.formatOptions.remove(.withColonSeparatorInTime)
        formatter.formatOptions.remove(.withDashSeparatorInDate)
        return formatter.string(from: self)
    }
}

// MARK: -

// swiftlint:disable:next function_parameter_count
private func cpuRadixSort<Splat>(splats: TypedMTLBuffer<Splat>, indexedDistances: inout TypedMTLBuffer<IndexedDistance>, temporaryIndexedDistances: inout [IndexedDistance], camera: simd_float4x4, model: simd_float4x4, reversed: Bool) where Splat: SortableSplatProtocol {
    guard !splats.isEmpty else {
        return
    }
    releaseAssert(splats.count <= indexedDistances.capacity, "Too few indexed distances \(indexedDistances.count) for \(splats.capacity) splats.")
    releaseAssert(splats.count <= temporaryIndexedDistances.count, "Too few temporary indexed distances \(temporaryIndexedDistances.count) for \(splats.count) splats.")
    indexedDistances.withUnsafeMutableBufferPointer { indexedDistances in
        let indexedDistances = UnsafeMutableBufferPointer<IndexedDistance>(start: indexedDistances.baseAddress, count: splats.count)
        // Compute distances.
        let modelView = camera.inverse * model
        releaseAssert(splats.count <= indexedDistances.count, "Cannot sort \(splats.count) splats into \(indexedDistances.count) indexed distances.")
        splats.withUnsafeBufferPointer { splats in
            for index in 0..<splats.count {
                let position = modelView * SIMD4<Float>(splats[index].floatPosition, 1.0)
                let distance = position.z * (reversed ? -1.0 : 1.0)
                indexedDistances[index] = .init(index: UInt32(index), distanceToCamera: distance)
            }
        }
        temporaryIndexedDistances.withUnsafeMutableBufferPointer { temporaryIndexedDistances in
            let temporaryIndexedDistances = UnsafeMutableBufferPointer<IndexedDistance>(start: temporaryIndexedDistances.baseAddress, count: splats.count)
            releaseAssert(splats.count == indexedDistances.count, "Mismatch between splats \(splats.count) and indexed distances \(indexedDistances.count).")
            releaseAssert(splats.count == temporaryIndexedDistances.count, "Mismatch between splats \(splats.count) and temporary indexed distances \(temporaryIndexedDistances.count).")
            releaseAssert(temporaryIndexedDistances.count == indexedDistances.count, "Mismatch between temporary indexed distances \(temporaryIndexedDistances.count) and indexed distances \(indexedDistances.count).")
            RadixSortCPU<IndexedDistance>().radixSort(input: indexedDistances, temp: temporaryIndexedDistances)
        }
    }
}

// MARK: -

extension IndexedDistance: RadixSortable {
    func key(shift: Int) -> Int {
        let bits = distanceToCamera.bitPattern
        let signMask: UInt32 = 0x80000000
        let key: UInt32 = (bits & signMask != 0) ? ~bits : bits ^ signMask
        return (Int(key) >> shift) & 0xFF
    }
}

// MARK: -

extension IndexedDistance: @retroactive Equatable {
    public static func == (lhs: IndexedDistance, rhs: IndexedDistance) -> Bool {
        lhs.distanceToCamera == rhs.distanceToCamera
            && lhs.index == rhs.index
    }
}

extension IndexedDistance: @unchecked @retroactive Sendable {
}

internal func releaseAssert(_ condition: @autoclosure () -> Bool, _ message: @autoclosure () -> String = String(), file: StaticString = #file, line: UInt = #line) {
    if !condition() {
        fatalError(message(), file: file, line: line)
    }
}

internal extension CPUSplatRadixSorter {
    static func sort(device: MTLDevice, splats: TypedMTLBuffer<Splat>, camera: simd_float4x4, model: simd_float4x4, reversed: Bool) throws -> SplatIndices {
        let sorter = CPUSplatRadixSorter<Splat>(device: device, capacity: splats.count)
        let indices = try sorter.sort(splats: splats, camera: camera, model: model, reversed: reversed)
        return .init(parameters: .init(camera: camera, model: model, reversed: reversed), indices: indices)
    }
}
