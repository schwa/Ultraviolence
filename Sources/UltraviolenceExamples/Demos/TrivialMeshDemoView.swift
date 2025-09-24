import GeometryLite3D
import Metal
import MetalKit
import simd
import SwiftUI
import Ultraviolence
import UltraviolenceExampleShaders
import UltraviolenceSupport
import UltraviolenceUI

public struct TrivialMeshDemoView: View {
    @State
    private var models: [Model] = []

    @State
    private var lighting: Lighting

    @State
    private var skyboxTexture: MTLTexture

    @State
    private var projection: any ProjectionProtocol = PerspectiveProjection()

    @State
    private var cameraMatrix: simd_float4x4 = .init(translation: [0, 1, 5])

    @State
    private var startTime = Date()

    @State
    private var showWireframe: Bool = false

    public init() {
        do {
            let device = _MTLCreateSystemDefaultDevice()

            // Create models from our TrivialMesh shapes
            // Platonic solids - scale to appear similar in visual size
            let tetrahedron = TrivialMesh.tetrahedron().scaled([1.8, 1.8, 1.8])
            let box = TrivialMesh.box() // Cube/Hexahedron
            let octahedron = TrivialMesh.octahedron().scaled([1.3, 1.3, 1.3])
            let dodecahedron = TrivialMesh.dodecahedron().scaled([1.2, 1.2, 1.2])
            let icosahedron = TrivialMesh.icosahedron().scaled([1.4, 1.4, 1.4])

            // 2D shapes (already flat on XY plane)
            let circle = TrivialMesh.circle()
            let quad = TrivialMesh.quad()
            let triangle = TrivialMesh.triangle()

            // Curved shapes
            let sphere = TrivialMesh.sphere()
            let torus = TrivialMesh.torus()
            let capsule = TrivialMesh.capsule()
            let cone = TrivialMesh.cone()
            let hemisphere = TrivialMesh.hemisphere()
            let cappedCone = TrivialMesh.cone(capped: true)
            let icoSphere = TrivialMesh.icoSphere()
            let cubeSphere = TrivialMesh.cubeSphere()

            // Convert TrivialMesh to Mesh for rendering
            let tetrahedronMesh = Mesh(tetrahedron, device: device)
            let boxMesh = Mesh(box, device: device)
            let octahedronMesh = Mesh(octahedron, device: device)
            let dodecahedronMesh = Mesh(dodecahedron, device: device)
            let icosahedronMesh = Mesh(icosahedron, device: device)
            let circleMesh = Mesh(circle, device: device)
            let quadMesh = Mesh(quad, device: device)
            let triangleMesh = Mesh(triangle, device: device)
            let sphereMesh = Mesh(sphere, device: device)
            let torusMesh = Mesh(torus, device: device)
            let capsuleMesh = Mesh(capsule, device: device)
            let coneMesh = Mesh(cone, device: device)
            let hemisphereMesh = Mesh(hemisphere, device: device)
            let cappedConeMesh = Mesh(cappedCone, device: device)
            let icoSphereMesh = Mesh(icoSphere, device: device)
            let cubeSphereMesh = Mesh(cubeSphere, device: device)

            self.models = [
                // Different sphere types in far back row
                .init(
                    id: "uvSphere",
                    mesh: sphereMesh,
                    modelMatrix: .init(translation: [-2, 0, -4]),
                    material: BlinnPhongMaterial(
                        ambient: .color([0.4, 0.3, 0.3]),
                        diffuse: .color([0.7, 0.5, 0.5]),
                        specular: .color([1, 1, 1]),
                        shininess: 100
                    )
                ),
                .init(
                    id: "icoSphere",
                    mesh: icoSphereMesh,
                    modelMatrix: .init(translation: [0, 0, -4]),
                    material: BlinnPhongMaterial(
                        ambient: .color([0.3, 0.4, 0.3]),
                        diffuse: .color([0.5, 0.7, 0.5]),
                        specular: .color([1, 1, 1]),
                        shininess: 100
                    )
                ),
                .init(
                    id: "cubeSphere",
                    mesh: cubeSphereMesh,
                    modelMatrix: .init(translation: [2, 0, -4]),
                    material: BlinnPhongMaterial(
                        ambient: .color([0.3, 0.3, 0.4]),
                        diffuse: .color([0.5, 0.5, 0.7]),
                        specular: .color([1, 1, 1]),
                        shininess: 100
                    )
                ),
                // Platonic solids in back row
                .init(
                    id: "tetrahedron",
                    mesh: tetrahedronMesh,
                    modelMatrix: .init(translation: [-4, 0, -2]),
                    material: BlinnPhongMaterial(
                        ambient: .color([0.5, 0.2, 0.2]),
                        diffuse: .color([0.8, 0.2, 0.2]),
                        specular: .color([1, 1, 1]),
                        shininess: 64
                    )
                ),
                .init(
                    id: "cube",
                    mesh: boxMesh,
                    modelMatrix: .init(translation: [-2, 0, -2]),
                    material: BlinnPhongMaterial(
                        ambient: .color([0.2, 0.2, 0.5]),
                        diffuse: .color([0.2, 0.2, 0.8]),
                        specular: .color([1, 1, 1]),
                        shininess: 32
                    )
                ),
                .init(
                    id: "octahedron",
                    mesh: octahedronMesh,
                    modelMatrix: .init(translation: [0, 0, -2]),
                    material: BlinnPhongMaterial(
                        ambient: .color([0.2, 0.5, 0.2]),
                        diffuse: .color([0.2, 0.8, 0.2]),
                        specular: .color([1, 1, 1]),
                        shininess: 128
                    )
                ),
                .init(
                    id: "dodecahedron",
                    mesh: dodecahedronMesh,
                    modelMatrix: .init(translation: [2, 0, -2]),
                    material: BlinnPhongMaterial(
                        ambient: .color([0.5, 0.3, 0.5]),
                        diffuse: .color([0.8, 0.4, 0.8]),
                        specular: .color([1, 1, 1]),
                        shininess: 96
                    )
                ),
                .init(
                    id: "icosahedron",
                    mesh: icosahedronMesh,
                    modelMatrix: .init(translation: [4, 0, -2]),
                    material: BlinnPhongMaterial(
                        ambient: .color([0.3, 0.4, 0.5]),
                        diffuse: .color([0.4, 0.6, 0.8]),
                        specular: .color([1, 1, 1]),
                        shininess: 80
                    )
                ),
                // Curved shapes in middle row
                .init(
                    id: "torus",
                    mesh: torusMesh,
                    modelMatrix: .init(translation: [-1, 0, 0]),
                    material: BlinnPhongMaterial(
                        ambient: .color([0.3, 0.3, 0.4]),
                        diffuse: .color([0.5, 0.5, 0.7]),
                        specular: .color([1, 1, 1]),
                        shininess: 100
                    )
                ),
                .init(
                    id: "capsule",
                    mesh: capsuleMesh,
                    modelMatrix: .init(translation: [1, 0, 0]),
                    material: BlinnPhongMaterial(
                        ambient: .color([0.4, 0.4, 0.3]),
                        diffuse: .color([0.7, 0.7, 0.5]),
                        specular: .color([1, 1, 1]),
                        shininess: 100
                    )
                ),
                // Additional curved shapes
                .init(
                    id: "cone",
                    mesh: coneMesh,
                    modelMatrix: .init(translation: [-4, 0, 0]),
                    material: BlinnPhongMaterial(
                        ambient: .color([0.3, 0.4, 0.3]),
                        diffuse: .color([0.5, 0.7, 0.5]),
                        specular: .color([1, 1, 1]),
                        shininess: 100
                    )
                ),
                .init(
                    id: "hemisphere",
                    mesh: hemisphereMesh,
                    modelMatrix: .init(translation: [4, 0, 0]),
                    material: BlinnPhongMaterial(
                        ambient: .color([0.4, 0.3, 0.4]),
                        diffuse: .color([0.7, 0.5, 0.7]),
                        specular: .color([1, 1, 1]),
                        shininess: 100
                    )
                ),
                .init(
                    id: "cappedCone",
                    mesh: cappedConeMesh,
                    modelMatrix: .init(translation: [-6, 0, 0]),
                    material: BlinnPhongMaterial(
                        ambient: .color([0.3, 0.3, 0.3]),
                        diffuse: .color([0.6, 0.6, 0.6]),
                        specular: .color([1, 1, 1]),
                        shininess: 100
                    )
                ),
                // 2D shapes in front row (keep them facing forward on XY plane)
                .init(
                    id: "circle",
                    mesh: circleMesh,
                    modelMatrix: .init(translation: [-3, 0, 2]),
                    material: BlinnPhongMaterial(
                        ambient: .color([0.5, 0.5, 0.2]),
                        diffuse: .color([0.8, 0.8, 0.2]),
                        specular: .color([1, 1, 1]),
                        shininess: 64
                    )
                ),
                .init(
                    id: "quad",
                    mesh: quadMesh,
                    modelMatrix: .init(translation: [0, 0, 2]),
                    material: BlinnPhongMaterial(
                        ambient: .color([0.5, 0.2, 0.5]),
                        diffuse: .color([0.8, 0.2, 0.8]),
                        specular: .color([1, 1, 1]),
                        shininess: 64
                    )
                ),
                .init(
                    id: "triangle",
                    mesh: triangleMesh,
                    modelMatrix: .init(translation: [3, 0, 2]),
                    material: BlinnPhongMaterial(
                        ambient: .color([0.2, 0.5, 0.5]),
                        diffuse: .color([0.2, 0.8, 0.8]),
                        specular: .color([1, 1, 1]),
                        shininess: 64
                    )
                )
            ]

            let lights = [
                Light(type: .spot, color: [1, 1, 1], intensity: 30)
            ]
            let positions = [
                SIMD3<Float>(2, 2, 3)
            ]
            let lighting = Lighting(
                ambientLightColor: [0.3, 0.3, 0.3],
                count: lights.count,
                lights: try device.makeBuffer(view: .init(count: lights.count), values: lights, options: []),
                lightPositions: try device.makeBuffer(view: .init(count: positions.count), values: positions, options: [])
            )
            self.lighting = lighting

            self.skyboxTexture = try! device.makeTextureCubeFromCrossTexture(texture: try device.makeTexture(name: "Skybox", bundle: .main))
        }
        catch {
            fatalError("\(error)")
        }
    }

    public var body: some View {
        WorldView(projection: $projection, cameraMatrix: $cameraMatrix, targetMatrix: .constant(nil)) {
            TimelineView(.animation) { timeline in
                RenderView { _, drawableSize in
                    let projectionMatrix = projection.projectionMatrix(for: drawableSize)
                    let viewMatrix = cameraMatrix.inverse
                    let viewProjectionMatrix = projectionMatrix * viewMatrix

                    try RenderPass {
                        try SkyboxRenderPipeline(projectionMatrix: projectionMatrix, cameraMatrix: cameraMatrix, texture: skyboxTexture)

                        GridShader(projectionMatrix: projectionMatrix, cameraMatrix: cameraMatrix)

                        try BlinnPhongShader {
                            try ForEach(models) { model in
                                try Draw { encoder in
                                    if showWireframe {
                                        encoder.setTriangleFillMode(.lines)
                                    }
                                    encoder.setVertexBuffers(of: model.mesh)
                                    encoder.draw(mesh: model.mesh)
                                }
                                .blinnPhongMaterial(model.material)
                                .transforms(.init(modelMatrix: model.modelMatrix, cameraMatrix: cameraMatrix, projectionMatrix: projectionMatrix))
                            }
                            .lighting(lighting)
                        }
                        .vertexDescriptor(MTLVertexDescriptor(models.first!.mesh.vertexDescriptor))
                        .depthCompare(function: .less, enabled: true)

                        try AxisLinesRenderPipeline(mvpMatrix: viewProjectionMatrix, scale: 10_000.0)
                    }
                }
                .metalDepthStencilPixelFormat(.depth32Float)
                .onChange(of: timeline.date) { _, _ in
                    let elapsed = Date().timeIntervalSince(startTime)

                    // Orbit the light in front of the shapes
                    let angle = Float(elapsed * 0.5) // Rotate once every ~12.5 seconds
                    lighting.lightPositions[SIMD3<Float>.self, 0] = simd_quatf(angle: angle, axis: [0, 1, 0]).act([2, 2, 3])
                }
            }
        }
        .onAppear {
            startTime = Date()
        }
        .overlay(alignment: .topLeading) {
            VStack(alignment: .leading) {
                Toggle("Wireframe", isOn: $showWireframe)
                    .toggleStyle(.switch)
                    .padding()
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
            .padding()
        }
    }

    struct Model: Identifiable {
        var id: String
        var mesh: Mesh
        var modelMatrix: float4x4
        var material: BlinnPhongMaterial
    }
}
