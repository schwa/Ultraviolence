#if os(iOS) || (os(macOS) && !arch(x86_64))
import GeometryLite3D
internal import os
import SwiftUI
import Ultraviolence
import UltraviolenceGaussianSplatShaders
import UltraviolenceSupport
import UltraviolenceUI

let logger: Logger? = Logger(subsystem: "gaussian-splats", category: "gaussian-splats")

public struct GaussianSplatView: View {
    private var splatCloud: SplatCloud<GPUSplat>
    private var projection: any ProjectionProtocol
    private var cameraMatrix: simd_float4x4
    private var modelMatrix: simd_float4x4 = .identity
    private var debugMode: GaussianSplatRenderPipeline.DebugMode

    @State
    private var sortManager: AsyncSortManager<GPUSplat>?

    public init(splatCloud: SplatCloud<GPUSplat>, projection: any ProjectionProtocol, cameraMatrix: simd_float4x4, debugMode: GaussianSplatRenderPipeline.DebugMode) {
        self.splatCloud = splatCloud
        self.projection = projection
        self.cameraMatrix = cameraMatrix
        self.debugMode = debugMode
    }

    public var body: some View {
        RenderView { _, drawableSize in
            try RenderPass {
                let projectionMatrix = projection.projectionMatrix(for: drawableSize)
                try GaussianSplatRenderPipeline(splatCloud: splatCloud, projectionMatrix: projectionMatrix, modelMatrix: modelMatrix, cameraMatrix: cameraMatrix, drawableSize: SIMD2<Float>(drawableSize), debugMode: debugMode)
            }
        }
        .onChange(of: splatCloud, initial: true) {
            sortManager = try! AsyncSortManager(device: _MTLCreateSystemDefaultDevice(), splatCloud: splatCloud, capacity: splatCloud.count, logger: logger)
            Task {
                let channel = await sortManager!.sortedIndicesChannel()
                for await sort in channel {
                    if sort.parameters.time < splatCloud.indexedDistances.parameters.time {
                        logger?.error("Out of order sort")
                        return
                    }

                    splatCloud.indexedDistances = sort
                }
            }
            requestSort()
        }
        .onChange(of: cameraMatrix) {
            requestSort()
        }
    }

    func requestSort() {
        guard let sortManager else {
            fatalError("No sort manager")
        }
        let parameters = SortParameters(camera: cameraMatrix, model: modelMatrix)
        sortManager.requestSort(parameters)
    }
}
#endif
