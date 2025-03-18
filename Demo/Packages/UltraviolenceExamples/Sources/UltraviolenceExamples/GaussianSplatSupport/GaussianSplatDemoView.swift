import GaussianSplatShaders
internal import os
import SwiftUI
import Ultraviolence
import UltraviolenceSupport
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
            if let splatCloud {
                WorldView(projection: $projection, cameraMatrix: $cameraMatrix, targetMatrix: .constant(nil)) {
                    GaussianSplatView(splatCloud: splatCloud, projection: projection, cameraMatrix: cameraMatrix, debugMode: debugMode)
                        .id(debugMode)
                }
            }
        }
        .modifier(SuperFilePickerModifier<[Antimatter15Splat]> { result in
            guard case let .success(items) = result else {
                return
            }
            process(splats: items[0])
        })
        .toolbar {
            PopoverButton("Utilities", systemImage: "gear") {
                Form {
                    Picker("Debug Mode", selection: $debugMode) {
                        ForEach(GaussianSplatRenderPipeline.DebugMode.allCases, id: \.self) { mode in
                            Text("\(String(describing: mode).camelCaseToTitleCase)").tag(mode)
                        }
                    }
                    URLPicker(title: "Splats", rootURL: Bundle.main.resourceURL!, utiTypes: [.antimatter15Splat, .json]) { url in
                        Task {
                            splatCloud = try! await load(url: url)
                        }
                    }
                }
                .padding()
                .frame(width: 320)
                .frame(minHeight: 240)
            }
        }
        .task {
            let url = Bundle.main.url(forResource: "centered_lastchance", withExtension: "splat")!
            splatCloud = try! await load(url: url)
        }
    }

    func load(url: URL) async throws -> SplatCloud<GPUSplat> {
        let antimatterSplats = try await [Antimatter15Splat](importing: url, contentType: nil)
        let gpuSplats = antimatterSplats.map(GPUSplat.init)
        let device = MTLCreateSystemDefaultDevice()!
        return try SplatCloud(device: device, splats: gpuSplats, cameraMatrix: cameraMatrix, modelMatrix: .identity)
    }

    func process(splats: [Antimatter15Splat]) {
        let splats = splats.map(GPUSplat.init)
        let device = _MTLCreateSystemDefaultDevice()
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

extension GaussianSplatDemoView: DemoView {
}

internal struct SuperFilePickerModifier <T>: ViewModifier where T: Transferable & Sendable {
    @State
    private var isDropTargeted: Bool = false

    @State
    private var isFileImporterPresented: Bool = false

    var callback: (Result<[T], Error>) throws -> Void

    init(callback: @escaping (Result<[T], Error>) throws -> Void) {
        self.callback = callback
    }

    func body(content: Content) -> some View {
        content
            .border(Color.blue, width: isDropTargeted ? 5 : 0)
            .toolbar {
                Button("Open…") {
                    isFileImporterPresented = true
                }
            }
            .dropDestination(for: T.self) { items, _ in
                do {
                    try callback(.success(items))
                    return true
                } catch {
                    return false
                }
            }
            isTargeted: { isTargeted in
                isDropTargeted = isTargeted
            }
            .fileImporter(isPresented: $isFileImporterPresented, allowedContentTypes: T.importedContentTypes()) { result in
                switch result {
                case .success(let url):
                    Task {
                        do {
                            let items = try await T(importing: url, contentType: nil)
                            try callback(.success([items]))
                        }
                        catch {
                            _ = try? callback(.failure(error))
                        }
                    }
                case .failure(let error):
                    _ = try? callback(.failure(error))
                }
            }
    }
}
