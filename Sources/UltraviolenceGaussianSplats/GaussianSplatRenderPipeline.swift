#if os(iOS) || (os(macOS) && !arch(x86_64))
import Foundation
import UltraviolenceGaussianSplatShaders
import Metal
import Ultraviolence

public struct GaussianSplatRenderPipeline: Element {
    public enum DebugMode: Int32, CaseIterable {
        case off = 0
        case wireframe = 1
        case filled = 2
    }

    var splatCloud: SplatCloud<GPUSplat>

    @UVState
    var vertexShader: VertexShader
    @UVState
    var fragmentShader: FragmentShader

    var vertexDescriptor: MTLVertexDescriptor
    var projectionMatrix: simd_float4x4
    var modelMatrix: simd_float4x4
    var cameraMatrix: simd_float4x4
    var drawableSize: SIMD2<Float>
    var debugMode: DebugMode

    public init(splatCloud: SplatCloud<GPUSplat>, projectionMatrix: simd_float4x4, modelMatrix: simd_float4x4, cameraMatrix: simd_float4x4, drawableSize: SIMD2<Float>, debugMode: DebugMode = .wireframe) throws {
        self.splatCloud = splatCloud
        self.projectionMatrix = projectionMatrix
        self.projectionMatrix[1][1] *= -1

        self.modelMatrix = modelMatrix
        self.cameraMatrix = cameraMatrix
        self.drawableSize = drawableSize
        self.debugMode = debugMode

        let shaderLibrary = try ShaderLibrary(bundle: Bundle.ultraviolenceGaussianSplatShaders(), namespace: "GaussianSplatAntimatter15RenderShaders")

        // TODO: #147 Give MTLFunctionConstantValues a nice type safe API.
        let constantValues = MTLFunctionConstantValues()
        withUnsafePointer(to: debugMode.rawValue) { pointer in
            // TODO: #148 We've hard coded the index here. Introspect the shader to get the index.
            constantValues.setConstantValue(pointer, type: .int, index: 2)
        }
        self.vertexShader = try shaderLibrary.function(named: "vertex_main", type: VertexShader.self, constantValues: constantValues)
        self.fragmentShader = try shaderLibrary.function(named: "fragment_main", type: FragmentShader.self, constantValues: constantValues)

        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float2
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.layouts[0].stride = MemoryLayout<SIMD2<Float>>.stride
        self.vertexDescriptor = vertexDescriptor
    }

    public var body: some Element {
        get throws {
            try RenderPipeline(vertexShader: vertexShader, fragmentShader: fragmentShader) {
                Draw { commandEncoder in
                    let vertices: [SIMD2<Float>] = [
                        [-1, -1], [-1, 1], [1, -1], [1, 1]
                    ]
                    if debugMode == .wireframe {
                        commandEncoder.setTriangleFillMode(.lines)
                    }
                    commandEncoder.setVertexUnsafeBytes(of: vertices, index: 0)
                    commandEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: splatCloud.count)
                }
                .parameter("splats", buffer: splatCloud.splats.unsafeMTLBuffer)
                .parameter("indexedDistances", buffer: splatCloud.indexedDistances.indices.unsafeMTLBuffer)
                .parameter("modelMatrix", value: modelMatrix)
                .parameter("viewMatrix", value: cameraMatrix.inverse)
                .parameter("projectionMatrix", value: projectionMatrix)
                .parameter("drawableSize", value: drawableSize)
                .parameter("scale", value: Float(2.0))
            }
            .vertexDescriptor(vertexDescriptor)
            .renderPipelineDescriptorModifier { renderPipelineDescriptor in
                renderPipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
                renderPipelineDescriptor.colorAttachments[0].rgbBlendOperation = .add
                renderPipelineDescriptor.colorAttachments[0].alphaBlendOperation = .add
                renderPipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .one
                renderPipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
                renderPipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
                renderPipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
            }
        }
    }
}
#endif
