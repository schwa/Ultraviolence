import GaussianSplatShaders
internal import os
import SwiftUI
import Ultraviolence
import UltraviolenceUI

public struct GaussianSplatDemoView: View {
    @State
    private var splatCloud: SplatCloud<GPUSplat>?

    @State
    private var projection: any ProjectionProtocol = PerspectiveProjection()

    @State
    private var cameraMatrix: simd_float4x4 = .init(translation: [0, 0.5, 1.5])

    @State
    private var debugMode: GaussianSplatRenderPipeline.DebugMode = .off

    public init() {
        // This line intentionally left blank.
    }

    public var body: some View {
        ZStack {
            Color.black
                .dropDestination(for: Array<Antimatter15Splat>.self) { splats, _ in
                    process(splats: splats[0])
                    return true
                }
            if let splatCloud {
                WorldView(projection: $projection, cameraMatrix: $cameraMatrix, targetMatrix: .constant(nil)) {
                    GaussianSplatView(splatCloud: splatCloud, projection: projection, cameraMatrix: cameraMatrix, debugMode: debugMode)
                        .id(debugMode)
                }
            }
        }
        .toolbar {
            Picker("debug mode", selection: $debugMode) {
                ForEach(GaussianSplatRenderPipeline.DebugMode.allCases, id: \.self) { mode in
                    Text("\(mode)").tag(mode)
                }
            }
        }
        .task {
            let url = Bundle.main.url(forResource: "centered_lastchance", withExtension: "splat")!
            let data = try! Data(contentsOf: url)
            let splats = data.withUnsafeBytes { buffer in
                buffer.withMemoryRebound(to: Antimatter15Splat.self, Array.init)
            }
            process(splats: splats)

            //            let url = Bundle.main.url(forResource: "6Splats", withExtension: "json")!
            //            let data = try! Data(contentsOf: url)
            //            let splats = try! JSONDecoder().decode([GenericSplat].self, from: data)
            //                .map(Antimatter15Splat.init)
            //            process(splats: splats)
        }
    }

    func process(splats: [Antimatter15Splat]) {
        let splats = splats.map(GPUSplat.init)
        let device = MTLCreateSystemDefaultDevice()!
        splatCloud = try! SplatCloud(device: device, splats: splats, cameraMatrix: cameraMatrix, modelMatrix: .identity)
    }
}

public struct GaussianSplatView: View {
    private var splatCloud: SplatCloud<GPUSplat>
    private var projection: any ProjectionProtocol
    private var cameraMatrix: simd_float4x4
    private var modelMatrix: simd_float4x4 = .identity
    private var debugMode: GaussianSplatRenderPipeline.DebugMode

    @State
    private var drawableSize: CGSize = .zero

    @State
    private var sortManager: AsyncSortManager<GPUSplat>?

    public init(splatCloud: SplatCloud<GPUSplat>, projection: any ProjectionProtocol, cameraMatrix: simd_float4x4, debugMode: GaussianSplatRenderPipeline.DebugMode) {
        self.splatCloud = splatCloud
        self.projection = projection
        self.cameraMatrix = cameraMatrix
        self.debugMode = debugMode
    }

    public var body: some View {
        RenderView {
            try RenderPass {
                let projectionMatrix = projection.projectionMatrix(for: drawableSize)
                try GaussianSplatRenderPipeline(splatCloud: splatCloud, projectionMatrix: projectionMatrix, modelMatrix: modelMatrix, cameraMatrix: cameraMatrix, drawableSize: SIMD2<Float>(drawableSize), debugMode: debugMode)
            }
            .environment(\.enableMetalLogging, true)
        }
        .onDrawableSizeChange { drawableSize = $0 }
        .onChange(of: splatCloud, initial: true) {
            sortManager = try! AsyncSortManager(device: MTLCreateSystemDefaultDevice()!, splatCloud: splatCloud, capacity: splatCloud.count, logger: logger)
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

extension Array: @retroactive Transferable where Element == Antimatter15Splat {
    public static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .antimatter15Splat) { data in
            data.withUnsafeBytes { buffer in
                buffer.withMemoryRebound(to: Antimatter15Splat.self, Array.init)
            }
        }
    }
}
