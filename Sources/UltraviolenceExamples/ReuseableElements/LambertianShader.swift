import CoreGraphics
import simd
import Ultraviolence

public struct LambertianShader <Content>: Element where Content: Element {
    var transforms: Transforms
    var color: SIMD3<Float>
    var vertexShader: VertexShader
    var fragmentShader: FragmentShader
    var lightDirection: SIMD3<Float>
    var content: Content

    public init(transforms: Transforms, color: SIMD3<Float>, lightDirection: SIMD3<Float>, @ElementBuilder content: () -> Content) throws {
        self.transforms = transforms
        self.color = color
        self.lightDirection = lightDirection
        let library = try ShaderLibrary(bundle: .ultraviolenceExampleShaders(), namespace: "LambertianShader")
        self.vertexShader = try library.vertex_main
        self.fragmentShader = try library.fragment_main
        self.content = content()
    }

    public var body: some Element {
        get throws {
            try RenderPipeline(vertexShader: vertexShader, fragmentShader: fragmentShader) {
                content
                    .parameter("color", value: color)
                    .parameter("projectionMatrix", value: transforms.projectionMatrix)
                    .parameter("modelMatrix", value: transforms.modelMatrix)
                    .parameter("viewMatrix", value: transforms.viewMatrix)
                    .parameter("lightDirection", value: lightDirection)
                    .parameter("cameraPosition", value: transforms.cameraMatrix.translation)
            }
        }
    }
}

public struct LambertianShaderInstanced <Content>: Element where Content: Element {
    var transforms: Transforms
    var colors: [SIMD3<Float>]
    var modelMatrices: [simd_float4x4]
    var vertexShader: VertexShader
    var fragmentShader: FragmentShader
    var lightDirection: SIMD3<Float>
    var content: Content

    public init(transforms: Transforms, colors: [SIMD3<Float>], modelMatrices: [simd_float4x4], lightDirection: SIMD3<Float>, @ElementBuilder content: () -> Content) throws {
        self.transforms = transforms
        self.colors = colors
        self.modelMatrices = modelMatrices
        self.lightDirection = lightDirection

        let library = try ShaderLibrary(bundle: .ultraviolenceExampleShaders(), namespace: "LambertianShader")
        self.vertexShader = try library.vertex_instanced
        self.fragmentShader = try library.fragment_main
        self.content = content()
    }

    public var body: some Element {
        get throws {
            try RenderPipeline(vertexShader: vertexShader, fragmentShader: fragmentShader) {
                content
                    .parameter("colors", values: colors)
                    .parameter("projectionMatrix", value: transforms.projectionMatrix)
                    .parameter("modelMatrices", values: modelMatrices)
                    .parameter("viewMatrix", value: transforms.viewMatrix)
                    .parameter("lightDirection", value: lightDirection)
                    .parameter("cameraPosition", value: transforms.cameraMatrix.translation)
            }
        }
    }
}
