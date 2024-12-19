import Metal
import UltraviolenceSupport

public extension EnvironmentValues {
    @Entry var device: MTLDevice?
    @Entry var commandQueue: MTLCommandQueue?
    @Entry var commandBuffer: MTLCommandBuffer?
    @Entry var renderCommandEncoder: MTLRenderCommandEncoder?
    @Entry var renderPassDescriptor: MTLRenderPassDescriptor?
    @Entry var renderPipelineState: MTLRenderPipelineState?
    @Entry var vertexDescriptor: MTLVertexDescriptor?
    @Entry var renderPipelineReflection: MTLRenderPipelineReflection?
    @Entry var depthStencilDescriptor: MTLDepthStencilDescriptor?
    @Entry var depthStencilState: MTLDepthStencilState?
    @Entry var computeCommandEncoder: MTLComputeCommandEncoder?
    @Entry var computePipelineState: MTLComputePipelineState?
}

public extension RenderPass {
    func vertexDescriptor(_ vertexDescriptor: MTLVertexDescriptor) -> some RenderPass {
        environment(\.vertexDescriptor, vertexDescriptor)
    }

    func depthStencilDescriptor(_ depthStencilDescriptor: MTLDepthStencilDescriptor) -> some RenderPass {
        environment(\.depthStencilDescriptor, depthStencilDescriptor)
    }

    func depthCompare(function: MTLCompareFunction, enabled: Bool) -> some RenderPass {
        depthStencilDescriptor(.init(depthCompareFunction: function, isDepthWriteEnabled: enabled))
    }
}

// MARK: -

public struct VertexShader {
    let function: MTLFunction

    public init(source: String) throws {
        let device = try MTLCreateSystemDefaultDevice().orThrow(.resourceCreationFailure)
        let library = try device.makeLibrary(source: source, options: nil)
        function = try library.functionNames.compactMap { library.makeFunction(name: $0) }.first { $0.functionType == .vertex }.orThrow(.resourceCreationFailure)
    }
}

public struct FragmentShader {
    let function: MTLFunction

    public init(source: String) throws {
        let device = try MTLCreateSystemDefaultDevice().orThrow(.resourceCreationFailure)
        let library = try device.makeLibrary(source: source, options: nil)
        function = try library.functionNames.compactMap { library.makeFunction(name: $0) }.first { $0.functionType == .fragment }.orThrow(.resourceCreationFailure)
    }
}

public extension VertexShader {
    var vertexDescriptor: MTLVertexDescriptor? {
        function.vertexDescriptor
    }
}

// MARK: -

// TODO: this should really be called renderpass
public struct Render <Content>: RenderPass, BodylessRenderPass where Content: RenderPass {
    var content: Content

    @Environment(\.commandBuffer)
    var commandBuffer

    public init(content: () -> Content) {
        self.content = content()
    }

    func _expandNode(_ node: Node) {
        // TODO: Move into BodylessRenderPass
        guard let graph = node.graph else {
            fatalError("Cannot build node tree without a graph.")
        }
        if node.children.isEmpty {
            node.children.append(graph.makeNode())
        }
        content.expandNode(node.children[0])
    }
}

public struct RenderPipeline <Content>: BodylessRenderPass where Content: RenderPass {
    public typealias Body = Never
    @Environment(\.device)
    var device

    @Environment(\.renderPassDescriptor)
    var renderPassDescriptor

    @Environment(\.vertexDescriptor)
    var vertexDescriptor

    @Environment(\.depthStencilDescriptor)
    var depthStencilDescriptor

    @Environment(\.depthStencilState)
    var depthStencilState

    @Environment(\.renderCommandEncoder)
    var renderCommandEncoder

    var vertexShader: VertexShader
    var fragmentShader: FragmentShader
    var content: Content

    @State
    var renderPipelineState: MTLRenderPipelineState?

    @State
    var reflection: MTLRenderPipelineReflection?

    public init(vertexShader: VertexShader, fragmentShader: FragmentShader, @RenderPassBuilder content: () -> Content) {
        self.vertexShader = vertexShader
        self.fragmentShader = fragmentShader
        self.content = content()
    }

    func _expandNode(_ node: Node) throws {
        // TODO: Move into BodylessRenderPass
        guard let graph = node.graph else {
            fatalError("Cannot build node tree without a graph.")
        }
        if node.children.isEmpty {
            node.children.append(graph.makeNode())
        }
        content.expandNode(node.children[0])

        let renderPassDescriptor = try renderPassDescriptor.orThrow(.missingEnvironment("renderPassDescriptor"))
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = vertexShader.function
        renderPipelineDescriptor.fragmentFunction = fragmentShader.function
        guard let vertexDescriptor = vertexDescriptor ?? vertexShader.vertexDescriptor else {
            throw UltraviolenceError.undefined
        }
        renderPipelineDescriptor.vertexDescriptor = vertexDescriptor
        let colorAttachment0Texture = try renderPassDescriptor.colorAttachments[0].texture.orThrow(.undefined)
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = colorAttachment0Texture.pixelFormat
        let depthAttachmentTexture = try renderPassDescriptor.depthAttachment.orThrow(.undefined).texture.orThrow(.undefined)
        renderPipelineDescriptor.depthAttachmentPixelFormat = depthAttachmentTexture.pixelFormat
        let device = try device.orThrow(.missingEnvironment("device"))
        let (renderPipelineState, reflection) = try device.makeRenderPipelineState(descriptor: renderPipelineDescriptor, options: .bindingInfo)
        self.renderPipelineState = renderPipelineState
        self.reflection = reflection

        if node.environmentValues[keyPath: \.depthStencilState] == nil, let depthStencilDescriptor {
            let depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)
            node.environmentValues[keyPath: \.depthStencilState] = depthStencilState
        }

        node.environmentValues[keyPath: \.renderPipelineState] = renderPipelineState
        node.environmentValues[keyPath: \.renderPipelineReflection] = reflection
    }

    func drawEnter() throws {
        let renderCommandEncoder = try renderCommandEncoder.orThrow(.missingEnvironment("renderCommandEncoder"))
        let renderPipelineState = try renderPipelineState.orThrow(.missingEnvironment("renderPipelineState"))

        if let depthStencilState {
            renderCommandEncoder.setDepthStencilState(depthStencilState)
        }

        renderCommandEncoder.setRenderPipelineState(renderPipelineState)
    }
}

public struct Draw: RenderPass, BodylessRenderPass {
    public typealias Body = Never

    @Environment(\.renderCommandEncoder)
    var renderCommandEncoder

    var encodeGeometry: (MTLRenderCommandEncoder) throws -> Void

    public init(encodeGeometry: @escaping (MTLRenderCommandEncoder) throws -> Void) {
        self.encodeGeometry = encodeGeometry
    }

    func _expandNode(_ node: Node) {
    }

    func drawEnter() {
        //        print("drawEnter")
        try! encodeGeometry(renderCommandEncoder!)
    }

    func drawExit() {
        //        print("drawExit")
    }
}

// struct ModifiedRenderPass<Content, Modifier>: RenderPass where Content: RenderPass, Modifier: RenderPassModifier, Modifier.Content == Content {
//    var content: Content
//    var modifier: Modifier
//
//    var body: some RenderPass {
//        modifier.body(content: content)
//    }
// }
//
// @MainActor public protocol RenderPassModifier {
//    associatedtype Body : RenderPass
//    @RenderPassBuilder @MainActor func body(content: Self.Content) -> Self.Body
//    associatedtype Content
// }
//

// TODO: Repalce with real MTL enum
enum ShaderType {
    case vertex
    case fragment
    case tile
    case object
    case mesh
    //    case compute
}

extension MTLRenderPipelineReflection {
    func binding(for name: String) throws -> (ShaderType, Int) {
        let typeAndindices: [(ShaderType, Int?)] = [
            (ShaderType.vertex, vertexBindings.first { $0.name == name }?.index),
            (ShaderType.fragment, fragmentBindings.first { $0.name == name }?.index),
            (ShaderType.tile, tileBindings.first { $0.name == name }?.index),
            (ShaderType.object, objectBindings.first { $0.name == name }?.index),
            (ShaderType.mesh, meshBindings.first { $0.name == name }?.index)
        ]
        let matches = typeAndindices.compactMap { type, index in
            index.map { (type, $0) }
        }
        if matches.isEmpty {
            fatalError("No binding for \(name)")
        }
        else if matches.count > 1 {
            fatalError("Ambiguous binding for \(name)")
        }
        return matches.first!
    }
}
