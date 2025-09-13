import DemoKit
import MetalKit
import SwiftUI
import Ultraviolence
import UltraviolenceSupport
import UltraviolenceUI

public struct SkyboxDemoView: View {
    @State
    private var texture: MTLTexture?

    @State
    private var projection: any ProjectionProtocol = PerspectiveProjection()

    @State
    private var cameraMatrix: simd_float4x4 = .init(translation: [0, 0, 1])

    @State
    private var drawableSize: CGSize = .zero

    public init() {
        // This line intentionally left blank.
    }

    public var body: some View {
        WorldView(projection: $projection, cameraMatrix: $cameraMatrix, targetMatrix: .constant(nil)) {
            RenderView {
                try RenderPass {
                    if let texture {
                        try SkyboxRenderPipeline(projectionMatrix: projection.projectionMatrix(for: drawableSize), cameraMatrix: cameraMatrix, texture: texture)
                    }
                }
            }
            .onDrawableSizeChange { drawableSize = $0 }
        }
        .task {
            do {
                texture = try testTexture()
            }
            catch {
                fatalError("Failed to create skybox texture: \(error)")
            }
        }
    }

    func testTexture() throws -> MTLTexture {
        let testView = ZStack {
            Image("Skybox")
                .resizable()

            Grid(horizontalSpacing: 0, verticalSpacing: 0) {
                GridRow {
                    Spacer()
                        .frame(width: 1_024, height: 1_024)
                    Color.green.opacity(0.2)
                        .overlay(Text("+Y").scaleEffect(10))
                        .frame(width: 1_024, height: 1_024)
                }
                GridRow {
                    Color.blue.opacity(0.2)
                        .overlay(Text("+X").scaleEffect(10))
                        .frame(width: 1_024, height: 1_024)

                    Color.red.opacity(0.2)
                        .overlay(Text("+Z").scaleEffect(10))
                        .frame(width: 1_024, height: 1_024)

                    Color.blue.opacity(0.2)
                        .overlay(Text("-X").scaleEffect(10))
                        .frame(width: 1_024, height: 1_024)

                    Color.red.opacity(0.2)
                        .overlay(Text("-Z").scaleEffect(10))
                        .frame(width: 1_024, height: 1_024)
                }
                GridRow {
                    Spacer()
                        .frame(width: 1_024, height: 1_024)
                    Color.green.opacity(0.2)
                        .overlay(Text("-Y").scaleEffect(10))
                        .frame(width: 1_024, height: 1_024)
                }
            }
        }
        .frame(width: 1_024 * 4, height: 1_024 * 3)
        let device = _MTLCreateSystemDefaultDevice()
        let texture2D = try device.makeTexture(content: testView)
        return try device.makeTextureCubeFromCrossTexture(texture: texture2D)
    }
}

extension SkyboxDemoView: DemoView {
    public static var metadata: DemoMetadata {
        DemoMetadata(
            name: "Skybox",
            description: "Environment mapping demonstration using cube textures for 360-degree backgrounds",
            keywords: ["skybox", "cubemap"]
        )
    }
}

struct SkyboxRenderPipeline: Element {
    let projectionMatrix: simd_float4x4
    let cameraMatrix: simd_float4x4
    let texture: MTLTexture

    @UVState
    var vertexShader: VertexShader

    @UVState
    var fragmentShader: FragmentShader

    init(projectionMatrix: simd_float4x4, cameraMatrix: simd_float4x4, texture: MTLTexture) throws {
        self.projectionMatrix = projectionMatrix
        self.cameraMatrix = cameraMatrix
        self.texture = texture
        let shaderBundle = Bundle.ultraviolenceExampleShaders().orFatalError()
        let shaderLibrary = try ShaderLibrary(bundle: shaderBundle, namespace: "SkyboxShader")
        vertexShader = try shaderLibrary.vertex_main
        fragmentShader = try shaderLibrary.fragment_main
    }

    var body: some Element {
        get throws {
            try RenderPipeline(vertexShader: vertexShader, fragmentShader: fragmentShader) {
                let positions: [Packed3<Float>] = [
                    // Front face (z = -1)
                    [ 1, -1, -1], [-1, -1, -1], [-1, 1, -1],  // Triangle 1 (inward)
                    [ 1, -1, -1], [-1, 1, -1], [ 1, 1, -1],  // Triangle 2 (inward)

                    // Back face (z = 1)
                    [ 1, -1, 1], [-1, 1, 1], [-1, -1, 1],  // Triangle 3 (inward)
                    [ 1, -1, 1], [ 1, 1, 1], [-1, 1, 1],  // Triangle 4 (inward)

                    // Bottom face (y = -1)
                    [ 1, -1, -1], [ 1, -1, 1], [-1, -1, 1],  // Triangle 5 (inward)
                    [ 1, -1, -1], [-1, -1, 1], [-1, -1, -1],  // Triangle 6 (inward)

                    // Top face (y = 1)
                    [ 1, 1, -1], [-1, 1, -1], [-1, 1, 1],  // Triangle 7 (inward)
                    [ 1, 1, -1], [-1, 1, 1], [ 1, 1, 1],  // Triangle 8 (inward)

                    // Left face (x = -1)
                    [-1, -1, -1], [-1, -1, 1], [-1, 1, 1],  // Triangle 9 (inward)
                    [-1, -1, -1], [-1, 1, 1], [-1, 1, -1],  // Triangle 10 (inward)

                    // Right face (x = 1)
                    [ 1, -1, -1], [ 1, 1, -1], [ 1, 1, 1],  // Triangle 11 (inward)
                    [ 1, -1, -1], [ 1, 1, 1], [ 1, -1, 1]  // Triangle 12 (inward)
                ]
                .map { $0 * 100 }
                Draw { encoder in
                    encoder.setVertexUnsafeBytes(of: positions, index: 0)
                    encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: positions.count)
                }
                .transforms(.init(cameraMatrix: cameraMatrix, projectionMatrix: projectionMatrix))
                .parameter("texture", texture: texture)
            }
            .vertexDescriptor(try vertexShader.inferredVertexDescriptor())
        }
    }
}
