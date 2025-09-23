import Ultraviolence
import UltraviolenceSupport
import UltraviolenceExampleShaders
import Metal
import simd

// TODO: Currently not using parents transforms
// TODO: Lighing is static once generated.

struct SceneGraphRenderPass: Element {

    var sceneGraph: SceneGraph
    var cameraMatrix: simd_float4x4
    var projectionMatrix: simd_float4x4
    var lighting: Lighting

    init(sceneGraph: SceneGraph, cameraMatrix: simd_float4x4, projectionMatrix: simd_float4x4) {
        self.sceneGraph = sceneGraph
        self.cameraMatrix = cameraMatrix
        self.projectionMatrix = projectionMatrix

        let lights = sceneGraph.filter { node in
            node.light != nil
        }.compactMap { node in
            let light = node.light!
            return (node.transform.translation, light)
        }
        self.lighting = try! .init(ambientLightColor: [1, 1, 1], lights: lights)
    }

    var body: some Element {
        get throws {
            try RenderPass {
                GridShader(projectionMatrix: projectionMatrix, cameraMatrix: cameraMatrix)
                try blinnPhong
//                try pbr
            }
        }
    }

    @ElementBuilder
    var blinnPhong: some Element {
        get throws {
            let nodesWithMeshes = try sceneGraph.filter { $0.mesh != nil }
            let blinnPhongNodes = nodesWithMeshes.filter {
                if case .blinnPhong = $0.material { return true }
                return false
            }
            return try BlinnPhongShader {
                try ForEach(Array(blinnPhongNodes.enumerated()), id: \.offset) { offset, node in
                    if let mesh = node.mesh, case let .blinnPhong(material) = node.material {
                        try Draw { encoder in
                            encoder.draw(mesh: mesh)
                        }
                        .blinnPhongMaterial(material)
                        .transforms(.init(modelMatrix: node.transform, cameraMatrix: cameraMatrix, projectionMatrix: projectionMatrix))
                    }
                }
                .lighting(lighting)
            }
            .vertexDescriptor(.default)
            .depthCompare(function: .less, enabled: true)

        }
    }

    @ElementBuilder
    var pbr: some Element {
        get throws {
            let nodesWithMeshes = try sceneGraph.filter { $0.mesh != nil }
            let pbrNodes = nodesWithMeshes.filter {
                if case .pbr = $0.material { return true }
                return false
            }
            return try PBRShader {
                try ForEach(Array(pbrNodes.enumerated()), id: \.offset) { offset, node in
                    if let mesh = node.mesh, case let .pbr(material) = node.material {
                        try Draw { encoder in
                            encoder.draw(mesh: mesh)
                        }
                        .pbrUniforms(material: material, modelTransform: node.transform, cameraMatrix: cameraMatrix, projectionMatrix: projectionMatrix)
                    }
                }
                .lighting(lighting)
            }
            .vertexDescriptor(.default)
            .depthCompare(function: .less, enabled: true)
        }
    }


}

extension SceneGraph {
    func visit(_ visitor: (Node) throws -> Void) rethrows {
        func _visitor(_ node: Node) throws {
            try visitor(node)
            for child in node.children {
                try _visitor(child)
            }
        }
        try _visitor(self.root)
    }

    func filter(_ isIncluded: (Node) throws -> Bool) rethrows -> [Node] {
        var result: [Node] = []
        try visit { node in
            if try isIncluded(node) {
                result.append(node)
            }
        }
        return result
    }

    func dump() {
        func _dump(_ node: Node, level: Int) {
            let indent = String(repeating: "  ", count: level)
            print("\(indent)- Node(name: \(node.label), mesh: \(node.mesh != nil ? "yes" : "no"), material: \(node.material != nil ? "\(type(of: node.material!))" : "no"))")
            for child in node.children {
                _dump(child, level: level + 1)
            }
        }
        _dump(root, level: 0)
    }
}



extension VertexDescriptor {
    static var `default`: Self {
        .init(attributes: [
            .init(semantic: .position, format: .float3, offset: 0, bufferIndex: 0),
            .init(semantic: .normal, format: .float3, offset: 0, bufferIndex: 0),
            .init(semantic: .texcoord, format: .float2, offset: 0, bufferIndex: 0),
            .init(semantic: .tangent, format: .float3, offset: 0, bufferIndex: 0),
            .init(semantic: .bitangent, format: .float3, offset: 0, bufferIndex: 0),
        ], layouts: [
            .init(bufferIndex: 0)
        ])
        .normalizingOffsets()
        .normalizingStrides()
    }
}

extension Element {
    func vertexDescriptor(_ vertexDescriptor: VertexDescriptor) -> some Element {
        let mtlVertexDescriptor = MTLVertexDescriptor(vertexDescriptor)
        return self.vertexDescriptor(mtlVertexDescriptor)
    }
}
