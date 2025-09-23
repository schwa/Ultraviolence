import GeometryLite3D
import Metal
import MetalKit
import ModelIO
import simd
import SwiftUI
import Ultraviolence
import UltraviolenceExampleShaders
import UltraviolenceSupport
import UltraviolenceUI

public struct PBRDemoView: View {
    @State private var projection: any ProjectionProtocol = PerspectiveProjection()
    @State private var cameraMatrix: simd_float4x4 = .init(translation: [0, 2, 6])
    @State private var selectedMaterial = MaterialPreset.gold
    @State private var customMaterial = PBRMaterialNew()
    @State private var animateLights = true
    @State private var showingInspector = true
    @State private var animationStartTime: Date?
    @State private var animationTime: Double = 0
    @State private var lighting: Lighting

    let teapot: MTKMesh
    let environmentTexture: MTLTexture

    public init() {
        teapot = MTKMesh.teapot(options: [.generateTangentBasis, .generateTextureCoordinatesIfMissing, .useSimpleTextureCoordinates])
        let device = MTLCreateSystemDefaultDevice()!
        let textureLoader = MTKTextureLoader(device: device)
        let envURL = Bundle.module.url(forResource: "IndoorEnvironmentHDRI013_1K-HDR", withExtension: "exr")!
        environmentTexture = try! textureLoader.newTexture(URL: envURL, options: [
            .textureUsage: MTLTextureUsage.shaderRead.rawValue,
            .textureStorageMode: MTLStorageMode.private.rawValue,
            .generateMipmaps: true,
            .SRGB: false
        ])

        lighting = try! .demo()
    }

    public var body: some View {
        TimelineView(.animation) { timeline in
            WorldView(projection: $projection, cameraMatrix: $cameraMatrix) {
                RenderView { context, drawableSize in
                    let projectionMatrix = projection.projectionMatrix(for: drawableSize)
                    let viewMatrix = cameraMatrix.inverse
                    let viewProjectionMatrix = projectionMatrix * viewMatrix


                    try RenderPass {
                        try AxisLinesRenderPipeline(mvpMatrix: viewProjectionMatrix, scale: 10_000.0)
                        try AxisAlignedWireframeBoxesRenderPipeline(mvpMatrix: viewProjectionMatrix, boxes: [.init(min: [-10, -10, -10], max: [10, 10, 10], color: [1, 1, 1, 1])])
                        LightingVisualizer(cameraMatrix: cameraMatrix, projectionMatrix: projectionMatrix, lighting: lighting)
                        try PBRShader {
                            try Draw(mtkMesh: teapot)
                                .pbrMaterial(currentMaterial)
                                .pbrUniforms(modelTransform: .identity, cameraMatrix: cameraMatrix, projectionMatrix: projectionMatrix)
                                .lighting(lighting)
                                .pbrEnvironment(environmentTexture)
                                .parameter("frameUniforms", functionType: .vertex, value: context.frameUniforms)
                                .parameter("frameUniforms", functionType: .fragment, value: context.frameUniforms)
                        }
                        .vertexDescriptor(teapot.vertexDescriptor)
                        .depthCompare(function: .less, enabled: true)
                    }
                }
                .metalDepthStencilPixelFormat(.depth32Float)
                .onChange(of: timeline.date) {
                    // Initialize start time on first frame
                    if animationStartTime == nil {
                        animationStartTime = timeline.date
                    }

                    // Calculate delta time from start
                    if let startTime = animationStartTime {
                        animationTime = timeline.date.timeIntervalSince(startTime)
                    }

                    LightingAnimator.run(date: timeline.date, lighting: &lighting)
                }
            }
        }
        .onChange(of: selectedMaterial, initial: false) {
            if selectedMaterial == .custom {
                customMaterial = PBRMaterialNew()
            }
        }
        .onChange(of: animateLights) {
            // Reset animation start time when toggling animation
            if animateLights {
                animationStartTime = nil
            }
        }
    }

    private var currentMaterial: PBRMaterialNew {
        selectedMaterial == .custom ? customMaterial : selectedMaterial.material
    }
}
