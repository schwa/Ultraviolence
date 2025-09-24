import simd
import Ultraviolence
import UltraviolenceExampleShaders

struct PBRMaterialNew: @unchecked Sendable {
    var albedo: ColorSource
    var normal: MTLTexture?
    var metallic: ColorSource
    var roughness: ColorSource
    var ambientOcclusion: ColorSource
    var emissive: ColorSource
    var emissiveIntensity: Float
    var clearcoat: Float
    var clearcoatRoughness: Float
    var softScattering: Float
    var softScatteringDepth: SIMD3<Float>
    var softScatteringTint: SIMD3<Float>
}

extension PBRMaterialNew {
    init() {
        albedo = .color([1, 1, 1])
        normal = nil
        metallic = .color(0) // TODO: use 1 scalar
        roughness = .color(0) // TODO: use 1 scalar
        ambientOcclusion = .color(1) // TODO: use 1 scalar
        emissive = .color([0, 0, 0])
        emissiveIntensity = 0.0
        clearcoat = 0.0
        clearcoatRoughness = 0.04
        softScattering = 0.0
        softScatteringDepth = [0.0, 0.0, 0.0]
        softScatteringTint = [1.0, 1.0, 1.0]
    }
}

extension PBRMaterialNew {
    func toArgumentBuffer() -> PBRMaterialArgumentBuffer {
        var argumentBuffer = PBRMaterialArgumentBuffer()
        argumentBuffer.albedo = albedo.toArgumentBuffer()
        //        argumentBuffer.normal = normal?.gpuResourceID
        argumentBuffer.metallic = metallic.toArgumentBuffer()
        argumentBuffer.roughness = roughness.toArgumentBuffer()
        argumentBuffer.ambientOcclusion = ambientOcclusion.toArgumentBuffer()
        argumentBuffer.emissive = emissive.toArgumentBuffer()
        argumentBuffer.emissiveIntensity = emissiveIntensity
        argumentBuffer.clearcoat = clearcoat
        argumentBuffer.clearcoatRoughness = clearcoatRoughness
        argumentBuffer.softScattering = softScattering
        argumentBuffer.softScatteringDepth = softScatteringDepth
        argumentBuffer.softScatteringTint = softScatteringTint
        return argumentBuffer
    }
}

extension Element {
    func pbrMaterial(_ material: PBRMaterialNew) -> some Element {
        //        self.parameter("material", functionType: .fragment, value: material)

        let argumentBuffer = material.toArgumentBuffer()

        return self.parameter("material", functionType: .fragment, value: argumentBuffer)
            .useResource(material.albedo, usage: .read, stages: .fragment)
            .useResource(material.metallic, usage: .read, stages: .fragment)
            .useResource(material.roughness, usage: .read, stages: .fragment)
            .useResource(material.ambientOcclusion, usage: .read, stages: .fragment)
            .useResource(material.emissive, usage: .read, stages: .fragment)
    }
}

extension PBRMaterialNew {
    init(albedo: SIMD3<Float> = [0.5, 0.5, 0.5], metallic: Float = 0.0, roughness: Float = 0.5, ambientOcclusion: Float = 1.0, emissive: SIMD3<Float> = [0.0, 0.0, 0.0], emissiveIntensity: Float = 0.0, clearcoat: Float = 0.0, clearcoatRoughness: Float = 0.04, softScattering: Float = 0.0, softScatteringDepth: SIMD3<Float> = [0.0, 0.0, 0.0], softScatteringTint: SIMD3<Float> = [1.0, 1.0, 1.0]) {
        self.init()
        self.albedo = .color(albedo)
        self.metallic = .color(metallic)
        self.roughness = .color(roughness)
        self.ambientOcclusion = .color(ambientOcclusion)
        self.emissive = .color(emissive)
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

enum MaterialPreset: String, CaseIterable {
    case gold = "Gold"
    case silver = "Silver"
    case copper = "Copper"
    case plastic = "Plastic"
    case rubber = "Rubber"
    case carPaint = "Car Paint"
    case lacqueredWood = "Lacquered Wood"
    case wetPlastic = "Wet Plastic"
    case wax = "Wax"
    case jade = "Jade"
    case skin = "Skin"
    case marble = "Marble"
    case custom = "Custom"

    var material: PBRMaterialNew {
        switch self {
        case .gold: return .gold
        case .silver: return .silver
        case .copper: return .copper
        case .plastic: return .plastic
        case .rubber: return .rubber
        case .carPaint: return .carPaint
        case .lacqueredWood: return .lacqueredWood
        case .wetPlastic: return .wetPlastic
        case .wax: return .wax
        case .jade: return .jade
        case .skin: return .skin
        case .marble: return .marble
        case .custom: return PBRMaterialNew()
        }
    }
}
