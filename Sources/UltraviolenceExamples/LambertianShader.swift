import CoreGraphics
import simd
import Ultraviolence
import UltraviolenceSupport

public struct LambertianShader <Content>: Element where Content: Element {
    var color: SIMD3<Float>
    var modelMatrix: simd_float4x4
    var cameraMatrix: simd_float4x4
    var projectionMatrix: simd_float4x4
    var vertexShader: VertexShader
    var fragmentShader: FragmentShader
    var lightDirection: SIMD3<Float>
    var content: Content

    public init(color: SIMD3<Float>, modelMatrix: simd_float4x4, cameraMatrix: simd_float4x4, projectionMatrix: simd_float4x4, lightDirection: SIMD3<Float>, @ElementBuilder content: () -> Content) throws {
        self.color = color
        self.modelMatrix = modelMatrix
        self.cameraMatrix = cameraMatrix
        self.projectionMatrix = projectionMatrix
        self.lightDirection = lightDirection
        let library = try ShaderLibrary(bundle: .module, namespace: "LambertianShader")
        self.vertexShader = try library.vertex_main
        self.fragmentShader = try library.fragment_main
        self.content = content()
    }

    public var body: some Element {
        get throws {
            try RenderPipeline(vertexShader: vertexShader, fragmentShader: fragmentShader) {
                content
                    .parameter("color", value: color)
                    .parameter("projectionMatrix", value: projectionMatrix)
                    .parameter("modelMatrix", value: modelMatrix)
                    .parameter("viewMatrix", value: cameraMatrix.inverse)
                    .parameter("lightDirection", value: lightDirection)
                    .parameter("cameraPosition", value: cameraMatrix.translation)
            }
        }
    }
}

public struct LambertianShaderInstanced <Content>: Element where Content: Element {
    var colors: [SIMD3<Float>]
    var modelMatrices: [simd_float4x4]
    var cameraMatrix: simd_float4x4
    var projectionMatrix: simd_float4x4
    var vertexShader: VertexShader
    var fragmentShader: FragmentShader
    var lightDirection: SIMD3<Float>
    var content: Content

    public init(colors: [SIMD3<Float>], modelMatrices: [simd_float4x4], cameraMatrix: simd_float4x4, projectionMatrix: simd_float4x4, lightDirection: SIMD3<Float>, @ElementBuilder content: () -> Content) throws {
        self.colors = colors
        self.modelMatrices = modelMatrices
        self.cameraMatrix = cameraMatrix
        self.projectionMatrix = projectionMatrix
        self.lightDirection = lightDirection

        let library = try ShaderLibrary(bundle: .module, namespace: "LambertianShader")
        self.vertexShader = try library.vertex_instanced
        self.fragmentShader = try library.fragment_main
        self.content = content()
    }

    public var body: some Element {
        get throws {
            try RenderPipeline(vertexShader: vertexShader, fragmentShader: fragmentShader) {
                content
                    .parameter("colors", values: colors)
                    .parameter("projectionMatrix", value: projectionMatrix)
                    .parameter("modelMatrices", values: modelMatrices)
                    .parameter("viewMatrix", value: cameraMatrix.inverse)
                    .parameter("lightDirection", value: lightDirection)
                    .parameter("cameraPosition", value: cameraMatrix.translation)
            }
        }
    }
}
