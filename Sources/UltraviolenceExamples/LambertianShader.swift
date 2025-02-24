import CoreGraphics
import simd
import Ultraviolence
internal import UltraviolenceSupport

public struct LambertianShader <Content>: Element where Content: Element {
    var color: SIMD4<Float>
    var drawableSize: SIMD2<Float>
    var modelMatrix: simd_float4x4
    var viewMatrix: simd_float4x4
    var cameraPosition: SIMD3<Float>
    var vertexShader: VertexShader
    var fragmentShader: FragmentShader
    var lightDirection: SIMD3<Float>
    var content: Content

    public init(color: SIMD4<Float>, drawableSize: SIMD2<Float>, modelMatrix: simd_float4x4, viewMatrix: simd_float4x4, cameraPosition: SIMD3<Float>, lightDirection: SIMD3<Float>, @ElementBuilder content: () -> Content) throws {
        self.color = color
        self.drawableSize = drawableSize
        self.modelMatrix = modelMatrix
        self.viewMatrix = viewMatrix
        self.cameraPosition = cameraPosition
        self.lightDirection = lightDirection

        let library = try ShaderLibrary(bundle: .module, namespace: "LambertianShader")
        self.vertexShader = try library.vertex_main
        self.fragmentShader = try library.fragment_main
        self.content = content()
    }

    public var body: some Element {
        RenderPipeline(vertexShader: vertexShader, fragmentShader: fragmentShader) {
            content
                .parameter("color", value: color)
                .parameter("projectionMatrix", value: PerspectiveProjection().projectionMatrix(for: drawableSize))
                .parameter("modelMatrix", value: modelMatrix)
                .parameter("viewMatrix", value: viewMatrix)
                .parameter("lightDirection", value: lightDirection)
                .parameter("cameraPosition", value: cameraPosition)
        }
    }
}
