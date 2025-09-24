import Metal
import MetalKit
import ModelIO
import simd
import Ultraviolence
import UltraviolenceExampleShaders
import UltraviolenceSupport

// MARK: - Global Uniforms

public struct PBRShader<Content>: Element where Content: Element {
    var vertexShader: VertexShader
    var fragmentShader: FragmentShader
    var content: Content

    public init(@ElementBuilder content: () throws -> Content) throws {
        let shaderBundle = Bundle.ultraviolenceExampleShaders().orFatalError()
        let shaderLibrary = try ShaderLibrary(bundle: shaderBundle, namespace: "PBR")
        self.vertexShader = try shaderLibrary.vertex_main
        self.fragmentShader = try shaderLibrary.fragment_main
        self.content = try content()
    }

    public var body: some Element {
        get throws {
            try RenderPipeline(label: "PBR Shader", vertexShader: vertexShader, fragmentShader: fragmentShader) {
                content
            }
        }
    }
}

// MARK: - Element Extensions for PBR

public extension Element {
    func pbrUniforms(modelTransform: float4x4, cameraMatrix: float4x4, projectionMatrix: float4x4) -> some Element {
        // Calculate matrices
        let normalMatrix = float3x3(modelTransform[0].xyz, modelTransform[1].xyz, modelTransform[2].xyz).transpose.inverse
        let viewMatrix = cameraMatrix.inverse
        let cameraPosition = cameraMatrix.translation
        let viewProjectionMatrix = projectionMatrix * viewMatrix

        // Set uniforms
        let uniforms = PBRUniforms(modelMatrix: modelTransform, normalMatrix: normalMatrix)

        let viewUniforms = [PBRAmplifiedUniforms(viewProjectionMatrix: viewProjectionMatrix, cameraPosition: cameraPosition)]

        return self
            .parameter("uniforms", functionType: .vertex, value: uniforms)
            .parameter("uniforms", functionType: .fragment, value: uniforms)
            .parameter("amplifiedUniforms", functionType: .vertex, values: viewUniforms)
            .parameter("amplifiedUniforms", functionType: .fragment, values: viewUniforms)
    }

    func pbrEnvironment(_ texture: MTLTexture?) -> some Element {
        self
            .parameter("environmentTexture", functionType: .fragment, texture: texture)
    }
}
