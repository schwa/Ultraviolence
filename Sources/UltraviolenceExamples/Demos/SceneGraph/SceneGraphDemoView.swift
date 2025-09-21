import SwiftUI
import Ultraviolence
import UltraviolenceSupport
import GeometryLite3D
import simd
import UltraviolenceUI
import Metal
import Panels

public struct SceneGraphDemoView: View {

    let sceneGraph: SceneGraph

    @State
    var projection: any ProjectionProtocol = PerspectiveProjection()

    @State
    var cameraMatrix: simd_float4x4 = simd_float4x4(translation: [0, 2, 5])

    public init() {
        let device = _MTLCreateSystemDefaultDevice()
        sceneGraph = SceneGraph.demo(device: device)
    }

    internal init(sceneGraph: SceneGraph) {
        self.sceneGraph = sceneGraph
    }

    public var body: some View {
        WorldView(projection: $projection, cameraMatrix: $cameraMatrix, targetMatrix: .constant(nil)) {
            RenderView { conext, drawableSize in
                SceneGraphRenderPass(sceneGraph: sceneGraph, cameraMatrix: cameraMatrix, projectionMatrix: projection.projectionMatrix(for: drawableSize))
            }
            .metalDepthStencilPixelFormat(.depth32Float)
            .panel(id: "SceneGraphEditorView", label: "Scene Graph") {
                SceneGraphEditorView(sceneGraph: sceneGraph)
            }
        }
    }
}

struct SceneGraphEditorView: View {
    let sceneGraph: SceneGraph

    @State
    var selectedNode: SceneGraph.Node.ID?

    var body: some View {
        List([sceneGraph.root], children: \.listChildren, selection: $selectedNode) { node in
            VStack {
                Text("Node: \(node.label)")
                if selectedNode == node.id {
                    LabeledContent("Transform") {
                        Text("\(node.transform)")
                    }
                    LabeledContent("Camera") {
                        Text("\(node.camera != nil ? "Yes" : "No")")
                    }
                    LabeledContent("Light") {
                        Text("\(node.light != nil ? "Yes" : "No")")
                    }
                    LabeledContent("Mesh") {
                        Text("\(node.mesh != nil ? "Yes" : "No")")
                    }
                    LabeledContent("Material") {
                        Text("\(node.material != nil ? "Yes" : "No")")
                    }
                }
            }
        }

    }
}

extension SceneGraph.Node {
    var listChildren: [SceneGraph.Node]? {
        return children.isEmpty ? nil : children
    }
}
