import simd
import Metal
import GeometryLite3D
import UltraviolenceExampleShaders

extension SceneGraph {
    static func demo(device: MTLDevice) -> SceneGraph {
        // Create root node
        let rootNode = Node(sceneGraph: nil, parent: nil)

        // Create camera node
        let cameraNode = Node(sceneGraph: nil, parent: rootNode, transform: float4x4(translation: [0, 0, 5]))
        cameraNode.camera = Camera(
            projection: PerspectiveProjection()
        )

        // Create light node
        let lightNode = Node(sceneGraph: nil, parent: rootNode, transform: float4x4(translation: [1, 1, 1]))
        lightNode.light = Light(type: .point, color: [1, 1, 1], intensity: 50.0)

        // Create cube node with BlinnPhong material
        let cubeNode = Node(sceneGraph: nil, parent: rootNode, transform: .identity)
        let cubeTrivialMesh = TrivialMesh.box()
        cubeNode.mesh = Mesh(cubeTrivialMesh, device: device)
        cubeNode.material = .blinnPhong(
            BlinnPhongMaterial(
                ambient: .color([0.1, 0.1, 0.1]),
                diffuse: .color([0.2, 0.2, 0.2]),
                specular: .color([1.0, 1.0, 1.0]),
                shininess: 32.0
            )
        )

        // Create cube node with BlinnPhong material
        let sphereNode = Node(sceneGraph: nil, parent: rootNode, transform: .init(translation: [1, 0, 0]))
        let sphereTrivialMesh = TrivialMesh.box()
        sphereNode.mesh = Mesh(sphereTrivialMesh, device: device)
        sphereNode.material = .pbr(PBRMaterial())

        // Set up hierarchy
        rootNode.children = [cameraNode, lightNode, cubeNode, sphereNode]

        // Create scene graph
        let sceneGraph = SceneGraph(root: rootNode)
        sceneGraph.currentCameraNode = cameraNode

        // Update scene graph references
        func updateSceneGraphReferences(_ node: Node) {
            node.sceneGraph = sceneGraph
            for child in node.children {
                updateSceneGraphReferences(child)
            }
        }
        updateSceneGraphReferences(rootNode)

        return sceneGraph
    }
}

