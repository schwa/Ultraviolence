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

    public init() {

    }

    public var body: some View {
        VStack {
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
    }
}

extension UTType {
    static let gltf = UTType(filenameExtension: "gltf")!
    static let glb = UTType(filenameExtension: "glb")!
}



