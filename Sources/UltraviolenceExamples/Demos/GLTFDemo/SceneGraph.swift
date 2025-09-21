import simd
import UltraviolenceExampleShaders
import GeometryLite3D

class SceneGraph {
    class Node {
        weak var sceneGraph: SceneGraph?
        weak var parent: Node?
        var label: String?
        var children: [Node]
        var transform: float4x4
        var mesh: Mesh?
        var camera: Camera?
        var light: Light?

        enum Material {
            case blinnPhong(BlinnPhongMaterial)
            case pbr(PBRMaterial)
        }

        var material: Material?

        init(sceneGraph: SceneGraph?, parent: Node?, children: [Node] = [], transform: float4x4 = .identity) {
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
    }
}

struct Camera {
    var projection: any ProjectionProtocol
}

