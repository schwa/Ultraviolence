import Metal
import Ultraviolence
import UltraviolenceExampleShaders

public struct BlinnPhongShader<Content>: Element where Content: Element {
    var vertexShader: VertexShader
    var fragmentShader: FragmentShader
    var transforms: Transforms

    var content: Content

    @UVEnvironment(\.device)
    var device

    public init(transforms: Transforms, @ElementBuilder content: () throws -> Content) throws {
        let device = MTLCreateSystemDefaultDevice().orFatalError()
        assert(device.argumentBuffersSupport == .tier2)
        let shaderBundle = Bundle.ultraviolenceExampleShaders().orFatalError()
        let shaderLibrary = try ShaderLibrary(bundle: shaderBundle)
        vertexShader = try shaderLibrary.BlinnPhongVertexShader
        fragmentShader = try shaderLibrary.BlinnPhongFragmentShader
        self.transforms = transforms

        self.content = try content()
    }

    public var body: some Element {
        get throws {
            let device = try device.orThrow(.missingEnvironment(\.device))

            try RenderPipeline(vertexShader: vertexShader, fragmentShader: fragmentShader) {
                content
                    .parameter("transforms", value: transforms)
            }
        }
    }
}

public extension Element {
    func blinnPhongMaterial(_ material: BlinnPhongMaterial) throws -> some Element {
        self
            .parameter("material", value: try material.toArgumentBuffer())
            .onWorkloadEnter { environmentValues in
                let renderCommandEncoder = environmentValues.renderCommandEncoder.orFatalError()
                material.useResource(on: renderCommandEncoder)
            }
    }
    func blinnPhongLighting(_ lighting: BlinnPhongLighting) throws -> some Element {
        self
            .parameter("lightingModel", value: try lighting.toArgumentBuffer())
            .onWorkloadEnter { environmentValues in
                let renderCommandEncoder = environmentValues.renderCommandEncoder.orFatalError()
                lighting.useResource(on: renderCommandEncoder)
            }
    }
}
