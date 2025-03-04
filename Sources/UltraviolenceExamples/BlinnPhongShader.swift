import Metal
import Ultraviolence
import UltraviolenceExampleShaders

public struct BlinnPhongShader<Content>: Element where Content: Element {
    var vertexShader: VertexShader
    var fragmentShader: FragmentShader
    var transforms: Transforms

    var lighting: BlinnPhongLighting
    var material: BlinnPhongMaterial
    var content: Content

    @UVEnvironment(\.device)
    var device

    public init(transforms: Transforms, lighting: BlinnPhongLighting, material: BlinnPhongMaterial, content: () throws -> Content) throws {
        let device = MTLCreateSystemDefaultDevice().orFatalError()
        assert(device.argumentBuffersSupport == .tier2)
        let shaderBundle = Bundle.ultraviolenceExampleShaders().orFatalError()
        let shaderLibrary = try ShaderLibrary(bundle: shaderBundle)
        vertexShader = try shaderLibrary.BlinnPhongVertexShader
        fragmentShader = try shaderLibrary.BlinnPhongFragmentShader
        self.transforms = transforms
        self.lighting = lighting
        self.material = material

        self.content = try content()
    }

    public var body: some Element {
        get throws {
            let device = try device.orThrow(.missingEnvironment(\.device))

            try RenderPipeline(vertexShader: vertexShader, fragmentShader: fragmentShader) {
                content
                    .onWorkloadEnter { environmentValues in
                        let renderCommandEncoder = environmentValues.renderCommandEncoder.orFatalError()
                        material.useResource(on: renderCommandEncoder)
                        lighting.useResource(on: renderCommandEncoder)
                    }
                    .parameter("transforms", value: transforms)
                    .parameter("lightingModel", value: try lighting.toArgumentBuffer())
                    .parameter("material", value: try material.toArgumentBuffer())
            }
        }
    }
}
