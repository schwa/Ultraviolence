import simd
import SwiftUI
import Ultraviolence
import UltraviolenceExampleShaders
import UltraviolenceSupport
import UltraviolenceUI

public struct GridShaderDemoView: View {
    @State
    private var drawableSize: CGSize = .zero

    @State
    private var projection: any ProjectionProtocol = PerspectiveProjection()

    @State
    private var cameraMatrix: simd_float4x4 = .init(translation: [0, 2, 4])

    public init() {
        // This line intentionally left blank.
    }

    public var body: some View {
        RenderView {
            try RenderPass {
                GridShader(projectionMatrix: projection.projectionMatrix(for: drawableSize), cameraMatrix: cameraMatrix)
            }
        }
        .onDrawableSizeChange { drawableSize = $0 }
    }
}

extension GridShaderDemoView: DemoView {
}

struct GridShader: Element {
    @State
    var vertexShader: VertexShader

    @State
    var fragmentShader: FragmentShader

    var projectionMatrix: simd_float4x4
    var cameraMatrix: simd_float4x4

    init(projectionMatrix: simd_float4x4, cameraMatrix: simd_float4x4) {
        self.projectionMatrix = projectionMatrix
        self.cameraMatrix = cameraMatrix
        let shaderBundle = Bundle.ultraviolenceExampleShaders().orFatalError()
        let shaderLibrary = try! ShaderLibrary(bundle: shaderBundle, namespace: "GridShader")
        vertexShader = try! shaderLibrary.vertex_main
        fragmentShader = try! shaderLibrary.fragment_main
    }

    var body: some Element {
        get throws {
            try RenderPipeline(vertexShader: vertexShader, fragmentShader: fragmentShader) {
                let transforms = Transforms(modelMatrix: .init(translation: [0, 0, 0]) * .init(xRotation: .degrees(90)), cameraMatrix: cameraMatrix, projectionMatrix: projectionMatrix)
                Draw { encoder in
                    let positions: [Packed3<Float>] = [
                        [-1, 1, 0], [-1, -1, 0], [1, 1, 0], [1, -1, 0]
                    ]
                    .map { $0 * 2_000 }
                    let textureCoordinates: [SIMD2<Float>] = [
                        [0, 1], [0, 0], [1, 1], [1, 0]
                    ]
                    //                    encoder.setTriangleFillMode(.lines)
                    encoder.setVertexUnsafeBytes(of: positions, index: 0)
                    encoder.setVertexUnsafeBytes(of: textureCoordinates, index: 1)
                    encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: positions.count)
                }
                .transforms(transforms)
                .parameter("gridColor", value: SIMD4<Float>(1, 1, 1, 1))
                .parameter("backgroundColor", value: SIMD4<Float>(0.1, 0.1, 0.1, 1))
                .parameter("gridScale", value: SIMD2<Float>(0.0005, 0.0005))
            }
        }
    }
}
