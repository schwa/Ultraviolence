#if os(iOS) || (os(macOS) && !arch(x86_64))
import GeometryLite3D
internal import os
import SwiftUI
import UltraviolenceGaussianSplats
import UltraviolenceGaussianSplatShaders
import UltraviolenceSupport

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
            SuperDownloadWidget("Download Splats…") { result in
                if case let .success(url) = result {
                    Task {
                        splatCloud = try! await load(url: url)
                    }
                }
            }
            .environment(\.superdownloadWidgetBookmarks, [
                URL(string: "https://huggingface.co/cakewalk/splat-data/resolve/main/train.splat")!
            ])
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

#endif
