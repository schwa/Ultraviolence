import SwiftUI
import Ultraviolence
import UltraviolenceSupport
import MetalKit

struct SkyboxDemoView: View {

    @State
    var texture: MTLTexture?

    @State
    var drawableSize: CGSize = .zero

    var body: some View {
        WorldView { projection, cameraMatrix in
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
            // Convert a skybox texture stored as a "cross" shape in a 2d texture into a texture cube:
            //     [5]
            // [1] [4] [0] [5]
            //     [2]

            let device = MTLCreateSystemDefaultDevice().orFatalError()
            let textureLoader = MTKTextureLoader(device: device)
            let texture = try! textureLoader.newTexture(name: "Skybox", scaleFactor: 1, bundle: .main, options: [:])
            let size = SIMD2<Int>(texture.width / 4, texture.height / 3)
            let cellWidth = texture.width / 4
            let cellHeight = texture.height / 3
            let cubeMapDescriptor = MTLTextureDescriptor()
            cubeMapDescriptor.textureType = .typeCube
            cubeMapDescriptor.pixelFormat = texture.pixelFormat
            cubeMapDescriptor.width = size.x
            cubeMapDescriptor.height = size.y
            let cubeMap = device.makeTexture(descriptor: cubeMapDescriptor)!
            let blit = try! BlitPass {
                Blit { encoder in
                    let origins: [SIMD2<Int>] = [
                        [2, 1],  [0, 1],  [1, 0],  [1, 2],  [1, 1],  [3, 1],
                    ]
                    for (slice, origin) in origins.enumerated() {
                        let origin = SIMD2<Int>(origin.x * cellWidth, origin.y * cellHeight)
                        encoder.copy(from: texture, sourceSlice: 0, sourceLevel: 0, sourceOrigin: .init(x: origin.x, y: origin.y, z: 0), sourceSize: .init(width: size.x, height: size.y, depth: 1), to: cubeMap, destinationSlice: slice, destinationLevel: 0, destinationOrigin: .init(x: 0, y: 0, z: 0))
                    }
                }
            }
            try! blit.run()
            self.texture = cubeMap
        }
    }
}

extension SkyboxDemoView: DemoView {
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
                    [ 1, -1, -1], [-1, -1, -1], [-1,  1, -1],  // Triangle 1 (inward)
                    [ 1, -1, -1], [-1,  1, -1], [ 1,  1, -1],  // Triangle 2 (inward)

                    // Back face (z = 1)
                    [ 1, -1,  1], [-1,  1,  1], [-1, -1,  1],  // Triangle 3 (inward)
                    [ 1, -1,  1], [ 1,  1,  1], [-1,  1,  1],  // Triangle 4 (inward)

                    // Bottom face (y = -1)
                    [ 1, -1, -1], [ 1, -1,  1], [-1, -1,  1],  // Triangle 5 (inward)
                    [ 1, -1, -1], [-1, -1,  1], [-1, -1, -1],  // Triangle 6 (inward)

                    // Top face (y = 1)
                    [ 1,  1, -1], [-1,  1, -1], [-1,  1,  1],  // Triangle 7 (inward)
                    [ 1,  1, -1], [-1,  1,  1], [ 1,  1,  1],  // Triangle 8 (inward)

                    // Left face (x = -1)
                    [-1, -1, -1], [-1, -1,  1], [-1,  1,  1],  // Triangle 9 (inward)
                    [-1, -1, -1], [-1,  1,  1], [-1,  1, -1],  // Triangle 10 (inward)

                    // Right face (x = 1)
                    [ 1, -1, -1], [ 1,  1, -1], [ 1,  1,  1],  // Triangle 11 (inward)
                    [ 1, -1, -1], [ 1,  1,  1], [ 1, -1,  1],  // Triangle 12 (inward)
                ]
                Draw { encoder in
                    encoder.setVertexUnsafeBytes(of: positions, index: 0)
                    encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: positions.count)
                }
                .transforms(.init(cameraMatrix: cameraMatrix, projectionMatrix: projectionMatrix))
                .parameter("texture", texture: texture)
            }
        }
    }
}

struct WorldView <Content>: View where Content: View {

    var content: (_ projection: any ProjectionProtocol, _ cameraMatrix: simd_float4x4) -> Content

    var projection: any ProjectionProtocol = PerspectiveProjection()

    @State
    var cameraMatrix: simd_float4x4 = .identity

    @State
    var rotation: simd_quatf = simd_quatf(angle: 0, axis: [0, 1, 0])

    var body: some View {
        content(projection, simd_float4x4(rotation))
            .arcBallRotationModifier(rotation: $rotation, radius: 0.0001)
    }

}

struct Packed3<Scalar> where Scalar : SIMDScalar {
    var x: Scalar
    var y: Scalar
    var z: Scalar
}

extension Packed3: ExpressibleByArrayLiteral {
    init(arrayLiteral elements: Scalar...) {
        x = elements[0]
        y = elements[1]
        z = elements[2]
    }
}
