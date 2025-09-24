import Foundation
import GeometryLite3D
import Metal
import MetalKit
import simd
import Ultraviolence
import UltraviolenceExampleShaders
import UltraviolenceSupport

struct PanoramaElement: Element {
    let projectionMatrix: simd_float4x4
    let cameraMatrix: simd_float4x4
    let panoramaTexture: MTLTexture
    let mesh: MTKMesh
    let showUV: Bool

    @UVState
    var vertexShader: VertexShader

    @UVState
    var fragmentShader: FragmentShader

    init(projectionMatrix: simd_float4x4, cameraMatrix: simd_float4x4, panoramaTexture: MTLTexture, mesh: MTKMesh, showUV: Bool = false) throws {
        self.projectionMatrix = projectionMatrix
        self.cameraMatrix = cameraMatrix
        self.panoramaTexture = panoramaTexture
        self.mesh = mesh
        self.showUV = showUV
        let shaderBundle = Bundle.ultraviolenceExampleShaders().orFatalError()
        let shaderLibrary = try ShaderLibrary(bundle: shaderBundle, namespace: "Panorama")
        vertexShader = try shaderLibrary.vertex_main
        fragmentShader = try shaderLibrary.fragment_main
    }

    var body: some Element {
        get throws {
            try RenderPipeline(vertexShader: vertexShader, fragmentShader: fragmentShader) {
                Draw(mtkMesh: mesh)
                    .transforms(Transforms(modelMatrix: .identity, cameraMatrix: cameraMatrix, projectionMatrix: projectionMatrix))
                    .parameter("panoramaTexture", texture: panoramaTexture)
                    .parameter("uniforms", value: PanoramaUniforms(
                        showUV: showUV ? 1 : 0,
                        cameraLocation: SIMD3<Float>(0, 0, 0),  // Camera at origin in model space
                        rotation: 0  // No rotation
                    ))
            }
            .vertexDescriptor(mesh.vertexDescriptor)
        }
    }
}

struct PanoramaMinimapElement: Element {
    let panoramaTexture: MTLTexture

    var vertexShader: VertexShader
    var fragmentShader: FragmentShader
    var vertexDescriptor: MTLVertexDescriptor

    init(panoramaTexture: MTLTexture) throws {
        self.panoramaTexture = panoramaTexture
        let shaderBundle = Bundle.ultraviolenceExampleShaders().orFatalError()
        let shaderLibrary = try ShaderLibrary(bundle: shaderBundle, namespace: "Panorama")
        vertexShader = try shaderLibrary.minimap_vertex
        fragmentShader = try shaderLibrary.minimap_fragment

        // Create vertex descriptor for the minimap quad
        vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[1].format = .float2
        vertexDescriptor.attributes[1].bufferIndex = 1
        vertexDescriptor.layouts[0].stride = MemoryLayout<SIMD3<Float>>.stride
        vertexDescriptor.layouts[1].stride = MemoryLayout<SIMD2<Float>>.stride
    }

    var body: some Element {
        get throws {
            try RenderPipeline(vertexShader: vertexShader, fragmentShader: fragmentShader) {
                Draw { encoder in
                    let vertices: [SIMD3<Float>] = [
                        [-1, -1, 0],
                        [ 1, -1, 0],
                        [-1, 1, 0],
                        [ 1, 1, 0]
                    ]
                    let texCoords: [SIMD2<Float>] = [
                        [0, 1],
                        [1, 1],
                        [0, 0],
                        [1, 0]
                    ]
                    encoder.setVertexBytes(vertices, length: vertices.count * MemoryLayout<SIMD3<Float>>.stride, index: 0)
                    encoder.setVertexBytes(texCoords, length: texCoords.count * MemoryLayout<SIMD2<Float>>.stride, index: 1)
                    encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
                }
                .parameter("panoramaTexture", texture: panoramaTexture)
            }
            .vertexDescriptor(vertexDescriptor)
        }
    }
}
