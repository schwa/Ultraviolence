import SwiftUI
import SwiftGLTF
import UltraviolenceUI
import UniformTypeIdentifiers

public struct GLTFDemoView: View {

    @State
    var url: URL?

    @State
    var document: Document?

    @State
    var sceneGraph: SceneGraph?

    @State
    var downloadedPath: URL?

    @State
    private var showingFilePicker = false

    @State
    private var availableFiles: [URL] = []

    public init() {

    }

    public var body: some View {
        VStack {
            HStack {
                DownloadButton(url: URL(string: "https://github.com/KhronosGroup/glTF-Sample-Assets/archive/refs/heads/main.zip")!, destinationName: "GLTFDownloads") { path in
                    downloadedPath = path
                    loadAvailableFiles(from: path)
                }

                if downloadedPath != nil && !availableFiles.isEmpty {
                    Button("Browse Files") {
                        showingFilePicker = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal)

            CachingImportButton(url: $url, identifier: "GLTFDemo", allowedContentTypes: [.gltf, .glb])
            Text("\(url)")
            if let document {
                Text("\(document.scenes.count) scene(s)")
                Text("\(document.meshes.count) mesh(s)")
            }
            if let sceneGraph {
                SceneGraphDemoView(sceneGraph: sceneGraph)
            }
        }
        .onChange(of: url, initial: true) {
            do {
                guard let url else { return }
                let container = try Container(url: url)
                document = container.document
                sceneGraph = try GLTGSceneGraphGenerator(container: container).generateSceneGraph()
            }
            catch {
                print("Failed to load GLTF: \(error)")
            }
        }
        .onChange(of: downloadedPath) {
            if let path = downloadedPath {
                loadAvailableFiles(from: path)
            }
        }
        .sheet(isPresented: $showingFilePicker) {
            GLTFFilePickerView(files: availableFiles, selectedURL: $url, isPresented: $showingFilePicker)
        }
    }

    private func loadAvailableFiles(from path: URL) {
        print("Loading files from: \(path.path)")

        let fileManager = FileManager.default

        // Check if the path exists and what's in it
        if fileManager.fileExists(atPath: path.path) {
            do {
                let contents = try fileManager.contentsOfDirectory(at: path, includingPropertiesForKeys: nil)
                print("Directory contents: \(contents.map { $0.lastPathComponent })")
            } catch {
                print("Error listing directory: \(error)")
            }
        } else {
            print("Path does not exist: \(path.path)")
        }

        let enumerator = fileManager.enumerator(at: path, includingPropertiesForKeys: [.isRegularFileKey])

        var files: [URL] = []
        while let fileURL = enumerator?.nextObject() as? URL {
            let pathExtension = fileURL.pathExtension.lowercased()
            if pathExtension == "gltf" || pathExtension == "glb" {
                files.append(fileURL)
                print("Found file: \(fileURL.lastPathComponent)")
            }
        }

        print("Total files found: \(files.count)")
        availableFiles = files.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }
}

extension UTType {
    static let gltf = UTType(filenameExtension: "gltf")!
    static let glb = UTType(filenameExtension: "glb")!
}



