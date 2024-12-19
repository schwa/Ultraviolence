// import AppKit
// import CoreGraphics
// import ImageIO
// import Metal
// import simd
// import Ultraviolence
// import UltraviolenceSupport
// import UniformTypeIdentifiers
// import UltraviolenceExamples
// import ModelIO
// import MetalKit
//
// struct TeapotDemo: RenderPass {
//    var mesh: MTKMesh
//    var modelMatrix: simd_float4x4
//    var cameraMatrix: simd_float4x4
//
//    init() throws {
//        let device = try MTLCreateSystemDefaultDevice().orThrow(.resourceCreationFailure)
//        let teapotURL = try Bundle.module.url(forResource: "teapot", withExtension: "obj").orThrow(.resourceCreationFailure)
//        let mdlAsset = MDLAsset(url: teapotURL, vertexDescriptor: nil, bufferAllocator: MTKMeshBufferAllocator(device: device))
//        // swiftlint:disable:next force_cast
//        let mdlMesh = try (mdlAsset.object(at: 0) as? MDLMesh).orThrow(.resourceCreationFailure)
//        mesh = try MTKMesh(mesh: mdlMesh, device: device)
//        modelMatrix = .identity
//        cameraMatrix = simd_float4x4(translation: [0, 2, 6])
//    }
//
//    var body: some RenderPass {
//        let viewMatrix = cameraMatrix.inverse
//        let cameraPosition = cameraMatrix.translation
//        Render {
//            LambertianShader(color: [1, 0, 0, 1], size: CGSize(width: 1600, height: 1200), modelMatrix: modelMatrix, viewMatrix: viewMatrix, cameraPosition: cameraPosition) {
//                Draw { encoder in
//                    encoder.draw(mesh)
//                }
//            }
//        }
//        .vertexDescriptor(MTLVertexDescriptor(mesh.vertexDescriptor))
//        .depthCompare(function: .less, enabled: true)
//    }
//
// }
//
// extension TeapotDemo {
//    @MainActor
//    static func main() throws {
//        let renderPass = try Self()
//        //        try MTLCaptureManager.shared().with {
//            let offscreenRenderer = try OffscreenRenderer(size: CGSize(width: 1_600, height: 1_200))
//            let image = try offscreenRenderer.render(renderPass).cgImage
//            let url = URL(fileURLWithPath: "output.png")
//            let imageDestination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
//            CGImageDestinationAddImage(imageDestination, image, nil)
//            CGImageDestinationFinalize(imageDestination)
//            NSWorkspace.shared.activateFileViewerSelecting([url.absoluteURL])
////        }
//    }
// }
