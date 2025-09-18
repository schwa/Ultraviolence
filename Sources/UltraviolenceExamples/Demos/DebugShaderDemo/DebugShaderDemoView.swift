import SwiftUI

import GeometryLite3D
import MetalKit
import simd
import Ultraviolence
import UltraviolenceExampleShaders
import UltraviolenceUI

public struct DebugShadersDemoView: View {
    @State
    private var projection: any ProjectionProtocol = PerspectiveProjection()

    @State
    private var cameraMatrix: simd_float4x4 = .init(translation: [0, 2, 6])

    @State
    private var debugMode: DebugShadersMode = .normal

    let teapot = try! MTKMesh(name: "teapot", bundle: .main, options: [.generateTangentBasis, .generateTextureCoordinatesIfMissing, .useSimpleTextureCoordinates])

    public init() {
    }

    public var body: some View {
        VStack(spacing: 0) {
            DebugModePicker(debugMode: $debugMode)
                .padding()

            WorldView(projection: $projection, cameraMatrix: $cameraMatrix) {
                RenderView { _, drawableSize in
                    let projectionMatrix = projection.projectionMatrix(for: drawableSize)
                    let viewMatrix = cameraMatrix.inverse
                    let viewProjectionMatrix = projectionMatrix * viewMatrix

                    try RenderPass(label: "Debug") {
                        try AxisLinesRenderPipeline(mvpMatrix: viewProjectionMatrix, scale: 10_000.0)

                        try AxisAlignedWireframeBoxesRenderPipeline(mvpMatrix: viewProjectionMatrix, boxes: [.init(min: [-10, -10, -10], max: [10, 10, 10], color: [1, 1, 1, 1])])

                        try! DebugRenderPipeline(modelMatrix: .identity, normalMatrix: .init(diagonal: [1, 1, 1]), debugMode: debugMode, lightPosition: [0, 10, 0], cameraPosition: cameraMatrix.translation, viewProjectionMatrix: viewProjectionMatrix) {
                            Draw(mtkMesh: teapot)
                        }
                        .vertexDescriptor(teapot.vertexDescriptor)
                        .depthCompare(function: .less, enabled: true)
                    }
                }
                .metalDepthStencilPixelFormat(.depth32Float)
            }
        }
    }
}

struct DebugModePicker: View {
    @Binding var debugMode: DebugShadersMode

    let debugModes: [(DebugShadersMode, String)] = [
        (.normal, "Normal"),
        (.texCoord, "Texture Coordinates"),
        (.tangent, "Tangent"),
        (.bitangent, "Bitangent"),
        (.worldPosition, "World Position"),
        (.localPosition, "Local Position"),
        (.uvDistortion, "UV Distortion"),
        (.tbnMatrix, "TBN Matrix"),
        (.vertexID, "Vertex ID"),
        (.faceNormal, "Face Normal"),
        (.uvDerivatives, "UV Derivatives"),
        (.checkerboard, "Checkerboard"),
        (.uvGrid, "UV Grid"),
        (.depth, "Depth"),
        (.wireframeOverlay, "Wireframe Overlay"),
        (.normalDeviation, "Normal Deviation"),
        (.amplificationID, "Amplification ID"),
        (.instanceID, "Instance ID"),
        (.quadThread, "Quad Thread"),
        (.simdGroup, "SIMD Group"),
        (.barycentricCoord, "Barycentric Coord"),
        (.frontFacing, "Front Facing"),
        (.sampleID, "Sample ID"),
        (.pointCoord, "Point Coord"),
        (.distanceToLight, "Distance to Light"),
        (.distanceToOrigin, "Distance to Origin"),
        (.distanceToCamera, "Distance to Camera")
    ]

    var body: some View {
        Picker("Debug Mode", selection: $debugMode) {
            ForEach(debugModes, id: \.0) { mode, label in
                Text(label).tag(mode)
            }
        }
        .pickerStyle(.menu)
    }
}
