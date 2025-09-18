import DemoKit
import GeometryLite3D
import Metal
import MetalKit
import SwiftUI
import Ultraviolence
import UltraviolenceSupport
import UltraviolenceUI
import UniformTypeIdentifiers

public struct PanoramaDemoView: View {
    enum MeshType: String, CaseIterable {
        case sphere = "Sphere"
        case box = "Box"
    }

    @State private var panoramaURL: URL?
    @State private var panoramaTexture: MTLTexture?
    @State private var projection: any ProjectionProtocol = PerspectiveProjection()
    @State private var cameraMatrix: simd_float4x4 = .init(translation: [0, 0, 1])
    @State private var mesh: MTKMesh?
    @State private var meshType: MeshType = .sphere
    @State private var showUV = false

    public init() {
    }

    public var body: some View {


        CachingImportWell(url: $panoramaURL, identifier: "panorama", allowedContentTypes: [.image]) { url in
            WorldView(projection: $projection, cameraMatrix: $cameraMatrix) {
                if let panoramaTexture, let mesh {
                    RenderView { _, drawableSize in
                        try RenderPass {
                            try PanoramaElement(projectionMatrix: projection.projectionMatrix(for: drawableSize), cameraMatrix: cameraMatrix, panoramaTexture: panoramaTexture, mesh: mesh, showUV: showUV)
                        }
                    }
                } else {
                    Text("Use 'Load Panorama' to load a 360° image")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if let panoramaTexture {
                    ZStack {
                        PanoramaMiniMapView(panoramaTexture: panoramaTexture, cameraMatrix: cameraMatrix)
                    }
                    .frame(width: 320, height: 320)
                    .padding(8)
                    .background(.thinMaterial, in: Circle())
                    .padding()
                    .allowsHitTesting(false)
                }
            }
        }
        .toolbar {
            Picker("Mesh", selection: $meshType) {
                ForEach(MeshType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }

            Toggle("Show UV", isOn: $showUV)

            CachingImportButton(url: $panoramaURL, identifier: "panorama", allowedContentTypes: [.image])
        }
        .onChange(of: panoramaURL, initial: true) {
            if let panoramaURL {
                loadPanoramaFromURL(panoramaURL)
            }
        }
        .onChange(of: meshType, initial: true) {
            switch meshType {
            case .sphere:
                mesh = MTKMesh.sphere(extent: [50, 50, 50], inwardNormals: true)
            case .box:
                mesh = MTKMesh.box(extent: [50, 50, 50], inwardNormals: true)
            }
        }
    }

    func loadPanoramaFromURL(_ url: URL) {
        Task {
            do {
                let device = _MTLCreateSystemDefaultDevice()
                let textureLoader = MTKTextureLoader(device: device)
                let texture = try await textureLoader.newTexture(URL: url, options: [.textureUsage: MTLTextureUsage.shaderRead.rawValue, .textureStorageMode: MTLStorageMode.private.rawValue])
                await MainActor.run {
                    self.panoramaTexture = texture
                }
            } catch {
                print("Failed to load panorama: \(error)")
            }
        }
    }
}

