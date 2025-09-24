#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif
import CoreImage
import Foundation
import GeometryLite3D
import MetalKit
import SwiftGLTF
import UltraviolenceExampleShaders
import UltraviolenceSupport

class GLTGSceneGraphGenerator {
    let container: Container
    let textureLoader: MTKTextureLoader

    init(container: Container) {
        self.container = container
        let device = _MTLCreateSystemDefaultDevice()
        textureLoader = MTKTextureLoader(device: device)
    }

    var document: Document {
        container.document
    }

    func generateSceneGraph() throws -> SceneGraph {
        let sceneGraph = SceneGraph(root: .init())
        let scene = try document.scene.map { try $0.resolve(in: document) } ?? document.scenes.first!
        try scene.nodes
            .map { try $0.resolve(in: document) }
            .map { try generateSceneGraphNode(from: $0) }
            .forEach {
                $0.parent = sceneGraph.root
                sceneGraph.root.children.append($0)
            }
        return sceneGraph
    }

    func generateSceneGraphNode(from node: Node) throws -> SceneGraph.Node {
        let uvNode = SceneGraph.Node()

        if let mesh = try node.mesh?.resolve(in: document) {
            try update(node: uvNode, from: mesh)
        }

        if let matrix = node.matrix {
            uvNode.transform = matrix
        }
        if let translation = node.translation {
            //            fatalError()
        }
        if let rotation = node.rotation {
            // fatalError()
        }
        if let scale = node.scale {
            // fatalError()
        }
        try node.children.map { try $0.resolve(in: document) }.map { try generateSceneGraphNode(from: $0) }.forEach {
            $0.parent = uvNode
            uvNode.children.append($0)
        }
        return uvNode
    }

    func update(node: SceneGraph.Node, from mesh: SwiftGLTF.Mesh) throws {
        // assert(mesh.primitives.count == 1)
        let primitive = mesh.primitives.first!

        let semantics: [SwiftGLTF.Mesh.Primitive.Semantic] = [
            .POSITION,
            .NORMAL,
            .TANGENT,
            .TEXCOORD_0,
            .TEXCOORD_1,
            .TEXCOORD_2,
            .COLOR_0,
            .JOINTS_0,
            .WEIGHTS_0
        ]
        print(try semantics.filter { try primitive.attributes[$0]?.resolve(in: container.document) != nil })

        var trivialMesh = TrivialMesh()
        if let positions = try primitive.value(semantic: .POSITION, type: SIMD3<Float>.self, in: container) {
            trivialMesh.positions = positions
        }
        if let normals = try primitive.value(semantic: .NORMAL, type: SIMD3<Float>.self, in: container) {
            trivialMesh.normals = normals
        }
        if let tangents = try primitive.value(semantic: .TANGENT, type: SIMD4<Float>.self, in: container) {
            // TODO: GLTF tangents are (x, y, z, w)???????? [FILE ME]
            trivialMesh.tangents = tangents.map(\.xyz)
        }

        // TODO: this is inefficient - we are getting and discarding this info already
        if let normals = try primitive.value(semantic: .NORMAL, type: SIMD3<Float>.self, in: container), let tangents = try primitive.value(semantic: .TANGENT, type: SIMD4<Float>.self, in: container) {
            trivialMesh.bitangents = zip(normals, tangents).map { normal, tangent in
                cross(normal, tangent.xyz) * tangent.w
            }
        }

        if let textureCoordinates = try primitive.value(semantic: .TEXCOORD_0, type: SIMD2<Float>.self, in: container) {
            trivialMesh.textureCoordinates = textureCoordinates
        }
        if let indices = try primitive.indices(type: UInt32.self, in: container) {
            assert(primitive.mode == .TRIANGLES)
            trivialMesh.indices = indices.map(Int.init)
        }

        if trivialMesh.textureCoordinates == nil {
            trivialMesh = trivialMesh.generateTextureCoordinates()
        }

        if trivialMesh.tangents == nil {
            trivialMesh = trivialMesh.generateTangents()
        }

        let device = _MTLCreateSystemDefaultDevice()
        node.mesh = Mesh(trivialMesh, device: device)

        if let material = try primitive.material?.resolve(in: document) {
            let uvMaterial = try makeMaterial(from: material)
            node.material = .pbr(uvMaterial)
        }
    }

    func makeMaterial(from material: SwiftGLTF.Material) throws -> PBRMaterialNew {
        var uvMaterial = PBRMaterialNew()
        if let pbrMetallicRoughness = material.pbrMetallicRoughness {
            uvMaterial.albedo = .color(pbrMetallicRoughness.baseColorFactor.xyz)
            uvMaterial.metallic = .color(pbrMetallicRoughness.metallicFactor)
            uvMaterial.roughness = .color(pbrMetallicRoughness.roughnessFactor)
            if let textureInfo = pbrMetallicRoughness.baseColorTexture {
                let mtlTexture = try mtlTexture(for: textureInfo)
                uvMaterial.albedo = .texture2D(mtlTexture)
            }
            if let textureInfo = pbrMetallicRoughness.metallicRoughnessTexture {
                let mtlTexture = try mtlTexture(for: textureInfo)
                uvMaterial.metallic = .texture2D(mtlTexture)
                uvMaterial.roughness = .texture2D(mtlTexture)
            }
        }

        return uvMaterial
    }
}

extension GLTGSceneGraphGenerator {
    func mtlTexture(for textureInfo: TextureInfo) throws -> MTLTexture {
        let texture = try textureInfo.index.resolve(in: document)
        let source = try texture.source!.resolve(in: document)
        let data = try container.data(for: source)
        let image = try CGImage.image(with: data)
        return try textureLoader.newTexture(cgImage: image, options: [:])
    }
}

extension Container {
    func data(for image: Image) throws -> Data {
        if let uri = image.uri {
            return try data(for: uri)
        }
        if let bufferView = try image.bufferView?.resolve(in: document) {
            return try data(for: bufferView)
        }
        fatalError()
    }
}

extension CGImage {
    static func image(with data: Data) throws -> CGImage {
        let source = CGImageSourceCreateWithData(data as CFData, nil)!
        let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        return image!
    }
}

extension SwiftGLTF.Mesh.Primitive {
    func value(semantic: SwiftGLTF.Mesh.Primitive.Semantic, type: SIMD2<Float>.Type, in container: Container) throws -> [SIMD2<Float>]? {
        guard let accessor = try attributes[semantic]?.resolve(in: container.document) else {
            return nil
        }
        assert(accessor.componentType == .FLOAT)
        let values = [SIMD2<Float>](withUnsafeData: try container.data(for: accessor))
        assert(values.count == accessor.count)
        assert(accessor.min == nil || accessor.max == nil || values.allSatisfy { $0.within(min: SIMD2<Float>(accessor.min!), max: SIMD2<Float>(accessor.max!)) })
        return values
    }

    func value(semantic: SwiftGLTF.Mesh.Primitive.Semantic, type: SIMD3<Float>.Type, in container: Container) throws -> [SIMD3<Float>]? {
        guard let accessor = try attributes[semantic]?.resolve(in: container.document) else {
            return nil
        }
        let values: [SIMD3<Float>]
        switch accessor.componentType {
        case .FLOAT:
            values = [Packed3<Float>](withUnsafeData: try container.data(for: accessor)).map {
                SIMD3<Float>($0.x, $0.y, $0.z)
            }
        default:
            fatalError()
        }

        assert(values.count == accessor.count)
        // assert(accessor.min == nil || accessor.max == nil || values.allSatisfy({ $0.within(min: SIMD3<Float>(accessor.min!), max: SIMD3<Float>(accessor.max!)) }))
        return values
    }

    func value(semantic: SwiftGLTF.Mesh.Primitive.Semantic, type: SIMD4<Float>.Type, in container: Container) throws -> [SIMD4<Float>]? {
        guard let accessor = try attributes[semantic]?.resolve(in: container.document) else {
            return nil
        }
        assert(accessor.componentType == .FLOAT)
        let values = [SIMD4<Float>](withUnsafeData: try container.data(for: accessor))
        assert(values.count == accessor.count)
        assert(accessor.min == nil || accessor.max == nil || values.allSatisfy { $0.within(min: SIMD4<Float>(accessor.min!), max: SIMD4<Float>(accessor.max!)) })
        return values
    }

    func indices(type: UInt32.Type, in container: Container) throws -> [UInt32]? {
        guard let indicesAccessor = try indices?.resolve(in: container.document) else {
            fatalError()
        }
        switch indicesAccessor.componentType {
        case .UNSIGNED_BYTE:
            let indices = [UInt8](try container.data(for: indicesAccessor))
            assert(indicesAccessor.min == nil || indicesAccessor.max == nil || indices.allSatisfy { (UInt8(indicesAccessor.min![0]) ... UInt8(indicesAccessor.max![0])).contains($0) })
            assert(indices.count == indicesAccessor.count)
            return indices.map { UInt32($0) }
        case .UNSIGNED_SHORT:
            let indices = [UInt16](withUnsafeData: try container.data(for: indicesAccessor))
            assert(indicesAccessor.min == nil || indicesAccessor.max == nil || indices.allSatisfy { (UInt16(indicesAccessor.min![0]) ... UInt16(indicesAccessor.max![0])).contains($0) })
            assert(indices.count == indicesAccessor.count)
            return indices.map { UInt32($0) }
        case .UNSIGNED_INT:
            let indices = [UInt32](withUnsafeData: try container.data(for: indicesAccessor))
            assert(indicesAccessor.min == nil || indicesAccessor.max == nil || indices.allSatisfy { (UInt32(indicesAccessor.min![0]) ... UInt32(indicesAccessor.max![0])).contains($0) })
            assert(indices.count == indicesAccessor.count)
            return indices
        default:
            fatalError()
        }
    }
}

extension Array {
    init(withUnsafeData data: Data) {
        self = data.withUnsafeBytes { buffer in
            let buffer = buffer.bindMemory(to: Element.self)
            return Array(buffer)
        }
    }
}

extension SIMD where Scalar == Float {
    func within(min: Self, max: Self) -> Bool {
        for n in 0 ..< scalarCount {
            if (min[n] ... max[n]).contains(self[n]) == false {
                return false
            }
        }
        return true
    }
}
