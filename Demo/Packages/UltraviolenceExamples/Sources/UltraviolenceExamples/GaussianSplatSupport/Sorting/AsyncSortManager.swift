internal import AsyncAlgorithms
import GaussianSplatShaders
@preconcurrency import Metal
internal import os
import simd

internal actor AsyncSortManager <Splat> where Splat: SplatProtocol {
    private var splatCloud: SplatCloud<Splat>
    private var _sortRequestChannel: AsyncChannel<SortParameters> = .init()
    private var _sortedIndicesChannel: AsyncChannel<SplatIndices> = .init()
    private var logger: Logger?
    private var sorter: CPUSplatRadixSorter<Splat>

    internal init(device: MTLDevice, splatCloud: SplatCloud<Splat>, capacity: Int, logger: Logger? = nil) throws {
        self.sorter = .init(device: device, capacity: capacity)
        self.splatCloud = splatCloud
        self.logger = logger
        Task(priority: .high) {
            do {
                try await self.startSorting()
            }
            catch is CancellationError {
                // This line intentionally left blank.
            }
            catch {
                logger?.log("Failed to sort splats: \(error)")
            }
        }
    }

    internal func sortedIndicesChannel() -> AsyncChannel<SplatIndices> {
        _sortedIndicesChannel
    }

    nonisolated
    internal func requestSort(_ parameters: SortParameters) {
        Task {
            await _sortRequestChannel.send(parameters)
        }
    }

    private func startSorting() async throws {
        let channel = _sortRequestChannel.removeDuplicates { lhs, rhs in
            lhs == rhs
        }
        ._throttle(for: .milliseconds(33.3333))

        for await parameters in channel {
            let start = CFAbsoluteTimeGetCurrent()
            let currentIndexedDistances = try sorter.sort(splats: splatCloud.splats, camera: parameters.camera, model: parameters.model, reversed: parameters.reversed)
            let end = CFAbsoluteTimeGetCurrent()
            let duration = end - start
            if duration > 0.033 {
                logger?.warning("### Sort took longer than expected (\(duration), \(duration / 0.033).")
            }
            await self._sortedIndicesChannel.send(.init(parameters: parameters, indices: currentIndexedDistances))
        }
    }
}

// MARK: -

// TODO: This really doesn't belong in AsyncSortManager considering it's NOT async.
internal extension AsyncSortManager {
    static func sort(device: MTLDevice, splats: TypedMTLBuffer<Splat>, camera: simd_float4x4, model: simd_float4x4, reversed: Bool) throws -> SplatIndices {
        let sorter = CPUSplatRadixSorter<Splat>(device: device, capacity: splats.count)
        let indices = try sorter.sort(splats: splats, camera: camera, model: model, reversed: reversed)
        return .init(parameters: .init(camera: camera, model: model, reversed: reversed), indices: indices)
    }
}
