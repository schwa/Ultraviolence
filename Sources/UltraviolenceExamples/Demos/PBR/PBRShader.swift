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
    func pbrUniforms(material: PBRMaterial, modelTransform: float4x4, cameraMatrix: float4x4, projectionMatrix: float4x4) -> some Element {
        // Calculate matrices
        let normalMatrix = float3x3(modelTransform[0].xyz, modelTransform[1].xyz, modelTransform[2].xyz).transpose.inverse
        let viewMatrix = cameraMatrix.inverse
        let cameraPosition = cameraMatrix.translation
        let viewProjectionMatrix = projectionMatrix * viewMatrix

        // Set uniforms
        let uniforms = PBRUniforms(material: material, modelMatrix: modelTransform, normalMatrix: normalMatrix)

        let viewUniforms = [PBRAmplifiedUniforms(viewProjectionMatrix: viewProjectionMatrix, cameraPosition: cameraPosition)]

        return self
            .parameter("uniforms", functionType: .vertex, value: uniforms)
            .parameter("uniforms", functionType: .fragment, value: uniforms)
            .parameter("amplifiedUniforms", functionType: .vertex, values: viewUniforms)
            .parameter("amplifiedUniforms", functionType: .fragment, values: viewUniforms)
    }

    func pbrLighting(_ lights: [PBRLight]) -> some Element {
        let lightCount = UInt32(lights.count)
        return self
            .parameter("lights", functionType: .fragment, values: lights)
            .parameter("lightCount", functionType: .fragment, value: lightCount)
    }

    func pbrEnvironment(_ texture: MTLTexture?) -> some Element {
        self
            .parameter("environmentTexture", functionType: .fragment, texture: texture)
    }
}

extension PBRMaterial {
    init(albedo: SIMD3<Float> = [0.5, 0.5, 0.5], metallic: Float = 0.0, roughness: Float = 0.5, ao: Float = 1.0, emissive: SIMD3<Float> = [0.0, 0.0, 0.0], emissiveIntensity: Float = 0.0, clearcoat: Float = 0.0, clearcoatRoughness: Float = 0.04, softScattering: Float = 0.0, softScatteringDepth: SIMD3<Float> = [0.0, 0.0, 0.0], softScatteringTint: SIMD3<Float> = [1.0, 1.0, 1.0]) {
        self.init()
        self.albedo = albedo
        self.metallic = metallic
        self.roughness = roughness
        self.ao = ao
        self.emissive = emissive
        self.emissiveIntensity = emissiveIntensity
        self.clearcoat = clearcoat
        self.clearcoatRoughness = clearcoatRoughness
        self.softScattering = softScattering
        self.softScatteringDepth = softScatteringDepth
        self.softScatteringTint = softScatteringTint
    }

    // Preset materials
    public static let gold = Self(albedo: [1.0, 0.766, 0.336], metallic: 1.0, roughness: 0.3)

    public static let silver = Self(albedo: [0.972, 0.960, 0.915], metallic: 1.0, roughness: 0.2)

    public static let copper = Self(albedo: [0.955, 0.637, 0.538], metallic: 1.0, roughness: 0.4)

    public static let plastic = Self(albedo: [0.5, 0.5, 0.5], metallic: 0.0, roughness: 0.5)

    public static let rubber = Self(albedo: [0.1, 0.1, 0.1], metallic: 0.0, roughness: 0.9)

    public static let carPaint = Self(albedo: [0.7, 0.1, 0.1], metallic: 0.0, roughness: 0.4, clearcoat: 1.0, clearcoatRoughness: 0.03)

    public static let lacqueredWood = Self(albedo: [0.4, 0.2, 0.1], metallic: 0.0, roughness: 0.6, clearcoat: 0.8, clearcoatRoughness: 0.1)

    public static let wetPlastic = Self(albedo: [0.2, 0.3, 0.8], metallic: 0.0, roughness: 0.3, clearcoat: 0.5, clearcoatRoughness: 0.05)

    public static let wax = Self(albedo: [0.9, 0.85, 0.7], metallic: 0.0, roughness: 0.5, softScattering: 0.8, softScatteringDepth: [1.0, 0.5, 0.2], softScatteringTint: [1.0, 0.9, 0.7])

    public static let jade = Self(albedo: [0.3, 0.6, 0.4], metallic: 0.0, roughness: 0.3, softScattering: 0.5, softScatteringDepth: [0.3, 0.8, 0.5], softScatteringTint: [0.4, 0.9, 0.6])

    public static let skin = Self(albedo: [0.8, 0.6, 0.5], metallic: 0.0, roughness: 0.4, softScattering: 0.7, softScatteringDepth: [1.0, 0.2, 0.1], softScatteringTint: [0.9, 0.5, 0.3])

    public static let marble = Self(albedo: [0.9, 0.9, 0.85], metallic: 0.0, roughness: 0.2, softScattering: 0.3, softScatteringDepth: [0.5, 0.5, 0.5], softScatteringTint: [0.95, 0.95, 0.9])
}
