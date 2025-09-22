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
    @State private var customMaterial = PBRMaterial()
    @State private var animateLights = true
    @State private var lightIntensity: Float = 10.0
    @State private var lightPosition = SIMD3<Float>(5, 5, 5)
    @State private var showingInspector = true
    @State private var animationStartTime: Date?
    @State private var animationTime: Double = 0

    let teapot: MTKMesh
    let environmentTexture: MTLTexture

    @State private var lights: [PBRLight] = [
        PBRLight(position: [5, 5, 5], color: [1, 1, 1], intensity: 10.0, type: .point),
        PBRLight(position: normalize([0.5, 1.0, 0.5]), color: [1.0, 0.95, 0.8], intensity: 3.0, type: .directional)
    ]

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
    }

    public var body: some View {
        TimelineView(.animation) { timeline in
            WorldView(projection: $projection, cameraMatrix: $cameraMatrix) {
                RenderView { context, drawableSize in
                    let projectionMatrix = projection.projectionMatrix(for: drawableSize)
                    let viewMatrix = cameraMatrix.inverse
                    let viewProjectionMatrix = projectionMatrix * viewMatrix

                    // Prepare light visualization boxes
                    let lightBoxes: [BoxInstance] = lights.compactMap { light in
                        guard light.type == .point else { return nil }
                        let pos = light.position
                        return BoxInstance(
                            min: pos - SIMD3<Float>(repeating: 0.2),
                            max: pos + SIMD3<Float>(repeating: 0.2),
                            color: SIMD4<Float>(light.color.x, light.color.y, light.color.z, 1.0)
                        )
                    }

                    try RenderPass {
                        try AxisLinesRenderPipeline(mvpMatrix: viewProjectionMatrix, scale: 10_000.0)
                        try AxisAlignedWireframeBoxesRenderPipeline(mvpMatrix: viewProjectionMatrix, boxes: [.init(min: [-10, -10, -10], max: [10, 10, 10], color: [1, 1, 1, 1])])

                        // Visualize light positions as small colored boxes
                        if !lightBoxes.isEmpty {
                            try AxisAlignedWireframeBoxesRenderPipeline(mvpMatrix: viewProjectionMatrix, boxes: lightBoxes)
                        }

                        try PBRShader {
                            Draw(mtkMesh: teapot)
                                .pbrUniforms(material: currentMaterial, modelTransform: .identity, cameraMatrix: cameraMatrix, projectionMatrix: projectionMatrix)
                                .pbrLighting(lights)
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

                    if animateLights {
                        updateAnimatedLights()
                    }
                }
            }
        }
        .inspector(isPresented: $showingInspector) {
            PBREditorView(
                selectedMaterial: $selectedMaterial,
                customMaterial: $customMaterial,
                animateLights: $animateLights,
                lightIntensity: $lightIntensity,
                lightPosition: $lightPosition,
                lights: $lights
            )
            .padding()
            .inspectorColumnWidth(ideal: 400)
        }
        .onChange(of: selectedMaterial, initial: false) {
            if selectedMaterial == .custom {
                customMaterial = PBRMaterial()
            }
        }
        .onChange(of: animateLights) {
            // Reset animation start time when toggling animation
            if animateLights {
                animationStartTime = nil
            }
        }
    }

    private var currentMaterial: PBRMaterial {
        selectedMaterial == .custom ? customMaterial : selectedMaterial.material
    }

    private func updateAnimatedLights() {
        let time = Float(animationTime)
        let radius: Float = 5.0
        let height: Float = 3.0 + sin(time * 0.5) * 2.0
        let animatedPosition = SIMD3<Float>(
            cos(time) * radius,
            height,
            sin(time) * radius
        )
        let hue = (sin(time * 0.3) + 1.0) * 0.5
        let color = hsvToRgb(h: hue * 60, s: 0.8, v: 1.0)
        let animatedIntensity = 10.0 + sin(time * 2.0) * 3.0
        let sunAngle = time * 0.2
        let sunDirection = normalize(SIMD3<Float>(
            cos(sunAngle) * 0.5,
            1.0,
            sin(sunAngle) * 0.5
        ))

        lights = [
            PBRLight(position: animatedPosition, color: color, intensity: Float(animatedIntensity), type: .point),
            PBRLight(position: sunDirection, color: [1.0, 0.95, 0.8], intensity: 3.0, type: .directional),
            // Add a second orbiting light in opposite phase
            PBRLight(
                position: SIMD3<Float>(
                    cos(time + .pi) * radius,
                    height,
                    sin(time + .pi) * radius
                ),
                color: hsvToRgb(h: (hue + 0.5).truncatingRemainder(dividingBy: 1.0) * 60, s: 0.8, v: 1.0),
                intensity: Float(animatedIntensity * 0.7),
                type: .point
            )
        ]
    }

    private func hsvToRgb(h: Float, s: Float, v: Float) -> SIMD3<Float> {
        let c = v * s
        let x = c * (1 - abs((h / 60).truncatingRemainder(dividingBy: 2) - 1))
        let m = v - c

        var rgb: SIMD3<Float>
        if h < 60 {
            rgb = [c, x, 0]
        } else if h < 120 {
            rgb = [x, c, 0]
        } else if h < 180 {
            rgb = [0, c, x]
        } else if h < 240 {
            rgb = [0, x, c]
        } else if h < 300 {
            rgb = [x, 0, c]
        } else {
            rgb = [c, 0, x]
        }

        return rgb + SIMD3<Float>(repeating: m)
    }
}
