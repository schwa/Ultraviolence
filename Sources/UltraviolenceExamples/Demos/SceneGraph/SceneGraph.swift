import simd
import UltraviolenceExampleShaders
import GeometryLite3D

class SceneGraph {
    class Node: Identifiable {
        enum Material {
            case blinnPhong(BlinnPhongMaterial)
            case pbr(PBRMaterial)
        }


        var id: ObjectIdentifier {
            ObjectIdentifier(self)
        }
        weak var sceneGraph: SceneGraph?
        weak var parent: Node?
        var label: String?
        var children: [Node]
        var transform: float4x4
        var camera: Camera?
        var light: Light?
        var mesh: Mesh?
        var material: Material?

        init(sceneGraph: SceneGraph? = nil, parent: Node? = nil, children: [Node] = [], transform: float4x4 = .identity) {
            self.sceneGraph = sceneGraph
            self.parent = parent
            self.children = children
            self.transform = transform
        }
    }

    var root: Node
    var currentCameraNode: Node?

    init(root: Node) {
        self.root = root
        root.sceneGraph = self
    }
}

struct Camera {
    var projection: any ProjectionProtocol
}

