import GeometryLite3D
import Metal
import MetalKit
import SwiftUI
import Ultraviolence
import UltraviolenceSupport
import UltraviolenceUI
import UniformTypeIdentifiers

struct PanoramaMiniMapView: View {
    let panoramaTexture: MTLTexture
    let cameraMatrix: simd_float4x4

    var body: some View {
        ZStack {
            RenderView { _, _ in
                try RenderPass {
                    try PanoramaMinimapElement(panoramaTexture: panoramaTexture)
                }
            }
            .metalClearColor(MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0))

            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) / 2

                // Get camera forward direction
                let cameraForward = -cameraMatrix[2]
                let cameraAngle = atan2(cameraForward.x, -cameraForward.z)

                // Convert to screen coordinates
                let dotRadius = radius * 0.8
                let dotX = center.x + CGFloat(cos(cameraAngle)) * dotRadius
                let dotY = center.y + CGFloat(sin(cameraAngle)) * dotRadius

                // Purple dot for camera position
                let dotRect = CGRect(x: dotX - 10, y: dotY - 10, width: 20, height: 20)
                context.fill(Path(ellipseIn: dotRect), with: .color(.accentColor))
            }
        }
    }
}
