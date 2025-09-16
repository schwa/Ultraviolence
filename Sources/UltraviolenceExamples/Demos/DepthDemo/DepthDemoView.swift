import SwiftUI
import Ultraviolence
import UltraviolenceSupport
import UltraviolenceUI
import GeometryLite3D
import simd
import MetalKit

public struct DepthDemoView: View {

    @State
    var projection: any ProjectionProtocol = PerspectiveProjection()

    @State
    var cameraMatrix: simd_float4x4 = .init(translation: [0, 0, 5])

    @State
    var drawableSize: CGSize = .zero

    @State
    var showDepthMap = true

    @State
    var colorTexture: MTLTexture?

    @State
    var depthTexture: MTLTexture?

    @State
    var adjustedDepthTexture: MTLTexture?

    let teapot = MTKMesh.teapot()

    public init() {
    }

    public var body: some View {
        WorldView(projection: $projection, cameraMatrix: $cameraMatrix) {
            RenderView {
                if let colorTexture, let depthTexture, let adjustedDepthTexture {
                    try RenderPass(label: "Teapot to Textures Pass") {
                        try teapotPipeline
                    }
                    .depthAttachment(depthTexture)
                    .renderPassDescriptorModifier { renderPassDescriptor in
                        renderPassDescriptor.colorAttachments[0].texture = colorTexture
                        renderPassDescriptor.colorAttachments[0].loadAction = .clear
                        renderPassDescriptor.colorAttachments[0].storeAction = .store

                        renderPassDescriptor.depthAttachment.texture = depthTexture
                        renderPassDescriptor.depthAttachment.loadAction = .clear
                        renderPassDescriptor.depthAttachment.storeAction = .store
                    }

                    try ComputePass(label: "ColorAdjust") {
                        ColorAdjustComputePipeline(inputSpecifier: .depth2D(depthTexture, nil), outputTexture: adjustedDepthTexture)
                    }

                    try RenderPass(label: "Depth to Screen Pass") {
                        try BillboardRenderPipeline(specifier:showDepthMap ? .texture2D(adjustedDepthTexture, nil) : .texture2D(colorTexture, nil), flippedY: true)
                    }
                }
            }
            .onDrawableSizeChange {
                drawableSize = $0

                let device = _MTLCreateSystemDefaultDevice()
                let colorDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: Int($0.width), height: Int($0.height), mipmapped: false)
                colorDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
                colorTexture = try? device.makeTexture(descriptor: colorDescriptor)
                colorTexture?.label = "Color Texture"

                let depthDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float, width: Int($0.width), height: Int($0.height), mipmapped: false)
                depthDescriptor.usage = [.renderTarget, .shaderRead]
                depthTexture = try? device.makeTexture(descriptor: depthDescriptor)
                depthTexture?.label = "Depth Texture"

                let adjustedDepthDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: Int($0.width), height: Int($0.height), mipmapped: false)
                adjustedDepthDescriptor.usage = [.renderTarget, .shaderRead, .shaderWrite]
                adjustedDepthTexture = try? device.makeTexture(descriptor: adjustedDepthDescriptor)
                adjustedDepthTexture?.label = "Adjusted Depth Texture"
            }
        }
        .overlay(alignment: .top) {
            Toggle("Show Depth Map", isOn: $showDepthMap)
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                .padding()

        }
    }

    
    var teapotPipeline: some Element {
        get throws {
            try FlatShader(textureSpecifier: .color([1, 1, 1])) {
                Draw(mtkMesh: teapot)
                    .transforms(Transforms(cameraMatrix: cameraMatrix, projectionMatrix: projection.projectionMatrix(for: drawableSize)))
            }
            .vertexDescriptor(teapot.vertexDescriptor)
            .depthCompare(function: .less, enabled: true)
        }
    }
}


