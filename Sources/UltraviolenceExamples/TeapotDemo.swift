#if canImport(AppKit)
import AppKit
#endif
import CoreGraphics
import ImageIO
import Metal
import MetalKit
import ModelIO
import simd
import Ultraviolence
internal import UltraviolenceSupport
import UniformTypeIdentifiers

public struct TeapotDemo: Element {
    @UVState
    var mesh: MTKMesh
    var color: SIMD3<Float>
    var modelMatrix: simd_float4x4
    var cameraMatrix: simd_float4x4
    var lightDirection: SIMD3<Float>

    @UVEnvironment(\.drawableSize)
    var drawableSize

    public init(modelMatrix: simd_float4x4, color: SIMD3<Float>, lightDirection: SIMD3<Float>) throws {
        let device = try MTLCreateSystemDefaultDevice().orThrow(.resourceCreationFailure)
        let teapotURL = try Bundle.module.url(forResource: "teapot", withExtension: "obj").orThrow(.resourceCreationFailure)
        let mdlAsset = MDLAsset(url: teapotURL, vertexDescriptor: nil, bufferAllocator: MTKMeshBufferAllocator(device: device))
        let mdlMesh = try (mdlAsset.object(at: 0) as? MDLMesh).orThrow(.resourceCreationFailure)
        mesh = try MTKMesh(mesh: mdlMesh, device: device)
        self.modelMatrix = modelMatrix
        cameraMatrix = simd_float4x4(translation: [0, 2, 6])
        self.color = color
        self.lightDirection = lightDirection
    }

    public var body: some Element {
        get throws {
            let drawableSize = SIMD2<Float>(drawableSize.orFatalError())
            let viewMatrix = cameraMatrix.inverse
            let cameraPosition = cameraMatrix.translation
            try LambertianShader(color: color, modelMatrix: modelMatrix, cameraMatrix: cameraMatrix, projectionMatrix: PerspectiveProjection().projectionMatrix(for: drawableSize), lightDirection: lightDirection) {
                Draw { encoder in
                    encoder.setVertexBuffers(of: mesh)
                    encoder.draw(mesh)
                }
            }
            .vertexDescriptor(MTLVertexDescriptor(mesh.vertexDescriptor))
            .depthCompare(function: .less, enabled: true)
        }
    }
}

public extension TeapotDemo {
    @MainActor
    // TODO: Make generic for any RenderPass
    static func main() throws {
        let size = CGSize(width: 1_600, height: 1_200)
        let element = try RenderPass {
            try Self(modelMatrix: .identity, color: [1, 0, 0], lightDirection: [-1, -2, -1])
        }
        let offscreenRenderer = try OffscreenRenderer(size: size)
        let image = try offscreenRenderer.render(element).cgImage
        let url = URL(fileURLWithPath: "output.png")
        // swiftlint:disable:next force_unwrapping
        let imageDestination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
        CGImageDestinationAddImage(imageDestination, image, nil)
        CGImageDestinationFinalize(imageDestination)
        #if canImport(AppKit)
        NSWorkspace.shared.activateFileViewerSelecting([url.absoluteURL])
        #endif
    }
}
