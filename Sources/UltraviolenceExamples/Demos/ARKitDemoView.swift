#if os(iOS)
import SwiftUI
import ARKit
import Observation
import Ultraviolence
import UltraviolenceSupport
import UltraviolenceUI
import CoreVideo
import Metal
import MetalKit
import UltraviolenceExampleShaders
import GeometryLite3D

public struct ARKitDemoView: View {

    @State
    var viewModel = ARKitDemoViewModel()

    let teapot: MTKMesh
    let environmentTexture: MTLTexture

    @State private var lights: [PBRLight] = [
        PBRLight(position: [5, 5, 5], color: [1, 1, 1], intensity: 10.0, type: .point),
        PBRLight(position: normalize([0.5, 1.0, 0.5]), color: [1.0, 0.95, 0.8], intensity: 3.0, type: .directional)
    ]

    public init() {
        teapot = try! MTKMesh.teapot(options: [.generateTangentBasis, .generateTextureCoordinatesIfMissing, .useSimpleTextureCoordinates])
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
        ZStack {
            RenderView { context, drawableSize in
                try RenderPass {
                    if let currentFrame = viewModel.currentFrame, let textureY = viewModel.currentTextureY, let textureCbCr = viewModel.currentTextureCbCr {
                        let cameraTransform = currentFrame.camera.transform
                        let cameraMatrix = cameraTransform.inverse
                        let orientation = UIInterfaceOrientation.portrait
                        let projectionMatrix = currentFrame.camera.projectionMatrix(for: orientation, viewportSize: drawableSize, zNear: 0.001, zFar: 1000)
                        let viewProjectionMatrix = projectionMatrix * cameraMatrix

                        try TextureBillboardPipeline(specifierA: .texture2D(textureY), specifierB: .texture2D(textureCbCr), flippedY: true, colorTransformFunctionName: "colorTransformYCbCrToRGB")

//                        try PBRShader {
//                            Draw(mtkMesh: teapot)
//                                .pbrUniforms(material: PBRMaterial.gold, modelTransform: .init(scale: [0.01, 0.01, 0.01]), cameraMatrix: cameraMatrix, projectionMatrix: projectionMatrix)
//                                .pbrLighting(lights)
//                                .pbrEnvironment(environmentTexture)
//                                .parameter("frameUniforms", functionType: .vertex, value: context.frameUniforms)
//                                .parameter("frameUniforms", functionType: .fragment, value: context.frameUniforms)
//                        }
//                        .vertexDescriptor(teapot.vertexDescriptor)
//                        .depthCompare(function: .less, enabled: true)


                        if let anchors = viewModel.session.currentFrame?.anchors, !anchors.isEmpty {
                            try AxisAlignedWireframeBoxesRenderPipeline(mvpMatrix: viewProjectionMatrix, boxes: currentFrame.anchors.map { anchor in
                                let position = anchor.transform.translation
                                return BoxInstance(min: position + [-0.05, -0.05, -0.05], max: position + [0.05, 0.05, 0.05], color: [1, 0, 1, 1])
                            })
                        }






                        try AxisLinesRenderPipeline(mvpMatrix: viewProjectionMatrix, scale: 10_000.0)
                    }
                }
            }
            .metalDepthStencilPixelFormat(.depth32Float)
            .metalClearColor(.init(red: 0, green: 0, blue: 0, alpha: 0))
            .onAppear {
                print("RenderView.onAppear")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .ignoresSafeArea()
        .overlay(alignment: .top) {
            if let cameraTrackingState = viewModel.cameraTrackingState {
                VStack {
                    Text("\(cameraTrackingState)")
                    Text("Y: \(viewModel.currentTextureY?.width ?? 0)x\(viewModel.currentTextureY?.height ?? 0)")
                    Text("CbCr: \(viewModel.currentTextureCbCr?.width ?? 0)x\(viewModel.currentTextureCbCr?.height ?? 0)")
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                .padding()
            }
        }
        .overlay {
            ARCoachingOverlayAdaptor(session: viewModel.session)
        }
    }
}

@Observable
class ARKitDemoViewModel: NSObject {
    var session: ARSession
    var configuration: ARConfiguration

    var cameraTrackingState: ARCamera.TrackingState?

    var currentFrame: ARFrame?
    var currentTextureY: MTLTexture?
    var currentTextureCbCr: MTLTexture?

    private var textureCache: CVMetalTextureCache?

    override init() {
        let device = _MTLCreateSystemDefaultDevice()

        session = .init()
        let configuration = ARWorldTrackingConfiguration()
//        configuration.environmentTexturing = .automatic
//        configuration.wantsHDREnvironmentTextures = true
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.sceneReconstruction = .meshWithClassification
        self.configuration = configuration

        var textureCache: CVMetalTextureCache?
        CVMetalTextureCacheCreate(nil, nil, device, nil, &textureCache)
        self.textureCache = textureCache

        super.init()

        let arSessionDelegateQueue = DispatchQueue(label: "ar.session.delegate")
        session.delegateQueue = arSessionDelegateQueue

        session.delegate = self
        session.run(configuration, options: [])
    }

    func start() {
    }
}

extension ARKitDemoViewModel: ARSessionObserver {
    func session(_ session: ARSession, didFailWithError error: any Error) {
        print(#function)
    }

    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        print(#function)
        self.cameraTrackingState = camera.trackingState
    }

    func sessionWasInterrupted(_ session: ARSession) {
        print(#function)
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        print(#function)
    }

    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        print(#function)
        return true
    }

    func session(_ session: ARSession, didOutputAudioSampleBuffer audioSampleBuffer: CMSampleBuffer) {
        print(#function)
    }

    func session(_ session: ARSession, didOutputCollaborationData data: ARSession.CollaborationData) {
        print(#function)
    }

    func session(_ session: ARSession, didChange geoTrackingStatus: ARGeoTrackingStatus) {
        print(#function)
    }
}

extension ARKitDemoViewModel: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Extract texture from the captured image
        let capturedImage = frame.capturedImage
        let pixelBuffer = capturedImage
        guard let textureCache = textureCache else {
            return
        }
        // ARKit provides YCbCr format with two planes
        guard CVPixelBufferGetPlaneCount(pixelBuffer) >= 2 else { return }

        // Create Y texture (luminance) from plane 0
        let widthY = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
        let heightY = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)

        var cvMetalTextureY: CVMetalTexture?
        let statusY = CVMetalTextureCacheCreateTextureFromImage(nil, textureCache, pixelBuffer, nil, .r8Unorm, widthY, heightY, 0, &cvMetalTextureY)


        // Create CbCr texture (chrominance) from plane 1
        let widthCbCr = CVPixelBufferGetWidthOfPlane(pixelBuffer, 1)
        let heightCbCr = CVPixelBufferGetHeightOfPlane(pixelBuffer, 1)

        var cvMetalTextureCbCr: CVMetalTexture?
        let statusCbCr = CVMetalTextureCacheCreateTextureFromImage(nil, textureCache, pixelBuffer, nil, .rg8Unorm, widthCbCr, heightCbCr, 1, &cvMetalTextureCbCr)

        guard statusY == kCVReturnSuccess, let cvMetalTextureY = cvMetalTextureY, statusCbCr == kCVReturnSuccess, let cvMetalTextureCbCr = cvMetalTextureCbCr else {
            return
        }

        currentFrame = frame
            currentTextureY = CVMetalTextureGetTexture(cvMetalTextureY)
            currentTextureY?.label = "AR Camera Y"
            currentTextureCbCr = CVMetalTextureGetTexture(cvMetalTextureCbCr)
            currentTextureCbCr?.label = "AR Camera CbCr"

    }

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        print("Add anchors")
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        print("Update anchors")
    }

    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        print(#function)
    }
}


//
//let coachingOverlay = ARCoachingOverlayView()
//coachingOverlay.goal = .tracking
//coachingOverlay.activityType = .play
//coachingOverlay.feedback = .success
//
//view.addSubview(coachingOverlay)

struct ARCoachingOverlayAdaptor: View {

    let session: ARSession

    var body: some View {
        ViewAdaptor {
            let coachingOverlay = ARCoachingOverlayView()
            return coachingOverlay
        }
        update: { (coachingOverlay: ARCoachingOverlayView) in
            coachingOverlay.session = session
        }
    }

}



#endif

