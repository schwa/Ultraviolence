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

public struct TeapotDemo: RenderPass {
    var mesh: MTKMesh
    var modelMatrix: simd_float4x4
    var cameraMatrix: simd_float4x4
    var size: CGSize

    public init(size: CGSize, modelMatrix: simd_float4x4) throws {
        let device = try MTLCreateSystemDefaultDevice().orThrow(.resourceCreationFailure)
        let teapotURL = try Bundle.module.url(forResource: "teapot", withExtension: "obj").orThrow(.resourceCreationFailure)
        let mdlAsset = MDLAsset(url: teapotURL, vertexDescriptor: nil, bufferAllocator: MTKMeshBufferAllocator(device: device))
        // swiftlint:disable:next force_cast
        let mdlMesh = try (mdlAsset.object(at: 0) as? MDLMesh).orThrow(.resourceCreationFailure)
        mesh = try MTKMesh(mesh: mdlMesh, device: device)
        self.modelMatrix = modelMatrix
        cameraMatrix = simd_float4x4(translation: [0, 2, 6])
        self.size = size
    }

    public var body: some RenderPass {
        let viewMatrix = cameraMatrix.inverse
        let cameraPosition = cameraMatrix.translation
        Render {
            // TODO: Size is hardcoded
            // swiftlint:disable:next force_try
            try! LambertianShader(color: [1, 0, 0, 1], size: size, modelMatrix: modelMatrix, viewMatrix: viewMatrix, cameraPosition: cameraPosition) {
                Draw { encoder in
                    encoder.draw(mesh)
                }
            }
        }
        .vertexDescriptor(MTLVertexDescriptor(mesh.vertexDescriptor))
        .depthCompare(function: .less, enabled: true)
    }
}

public extension TeapotDemo {
    @MainActor
    // TODO: Make generic for any RenderPass
    static func main() throws {
        let size = CGSize(width: 1_600, height: 1_200)
        let renderPass = try Self(size: size, modelMatrix: .identity)
        let offscreenRenderer = try OffscreenRenderer(size: size)
        let image = try offscreenRenderer.render(renderPass).cgImage
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
