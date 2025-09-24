import Metal
import Ultraviolence
import UltraviolenceExampleShaders
import UltraviolenceSupport

public struct BlinnPhongMaterial {
    public var ambient: ColorSource
    public var diffuse: ColorSource
    public var specular: ColorSource
    public var shininess: Float

    public init(ambient: ColorSource, diffuse: ColorSource, specular: ColorSource, shininess: Float) {
        self.ambient = ambient
        self.diffuse = diffuse
        self.specular = specular
        self.shininess = shininess
    }
}

extension BlinnPhongMaterial {
    func toArgumentBuffer() throws -> BlinnPhongMaterialArgumentBuffer {
        var result = BlinnPhongMaterialArgumentBuffer()
        result.ambient = ambient.toArgumentBuffer()
        result.diffuse = diffuse.toArgumentBuffer()
        result.specular = specular.toArgumentBuffer()
        result.shininess = shininess
        return result
    }
}

extension Element {
    func blinnPhongMaterial(_ material: BlinnPhongMaterial) throws -> some Element {
        self
            .parameter("material", value: try material.toArgumentBuffer())
            // TODO: We have to expand this
            .useResource(material.ambient.texture2D, usage: .read, stages: .fragment)
            .useResource(material.diffuse.texture2D, usage: .read, stages: .fragment)
            .useResource(material.specular.texture2D, usage: .read, stages: .fragment)
    }
}
