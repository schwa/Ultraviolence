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
}

// MARK: -

public struct VertexShader {
    let function: MTLFunction

    public init(source: String) throws {
        let device = MTLCreateSystemDefaultDevice()!
        let library = try device.makeLibrary(source: source, options: nil)
        function = library.functionNames.compactMap { library.makeFunction(name: $0) }.first { $0.functionType == .vertex }!
    }
}

public struct FragmentShader {
    let function: MTLFunction

    public init(source: String) throws {
        let device = MTLCreateSystemDefaultDevice()!
        let library = try device.makeLibrary(source: source, options: nil)
        function = library.functionNames.compactMap { library.makeFunction(name: $0) }.first { $0.functionType == .fragment }!
    }
}

public extension VertexShader {
    var vertexDescriptor: MTLVertexDescriptor? {
        function.vertexDescriptor
    }
}

extension MTLFunction {
    var vertexDescriptor: MTLVertexDescriptor? {
        guard let vertexAttributes else {
            return nil
        }
        let vertexDescriptor = MTLVertexDescriptor()

        var totalStride: Int = 0
        for attribute in vertexAttributes {
            switch attribute.attributeType {
            case .float2:
                vertexDescriptor.attributes[attribute.attributeIndex].format = .float2
                vertexDescriptor.layouts[attribute.attributeIndex].stride = MemoryLayout<SIMD2<Float>>.stride
                totalStride += MemoryLayout<SIMD2<Float>>.stride
            default:
                fatalError()
            }
        }
        vertexDescriptor.layouts[0].stride = totalStride
        return vertexDescriptor
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

    func drawEnter() {
    }

    func drawExit() {
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

    func _expandNode(_ node: Node) {
        // TODO: Move into BodylessRenderPass
        guard let graph = node.graph else {
            fatalError("Cannot build node tree without a graph.")
        }
        if node.children.isEmpty {
            node.children.append(graph.makeNode())
        }
        content.expandNode(node.children[0])

        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.vertexFunction = vertexShader.function
        renderPipelineDescriptor.fragmentFunction = fragmentShader.function
        renderPipelineDescriptor.vertexDescriptor = vertexDescriptor ?? vertexShader.vertexDescriptor!
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = renderPassDescriptor!.colorAttachments[0].texture!.pixelFormat
        renderPipelineDescriptor.depthAttachmentPixelFormat = renderPassDescriptor!.depthAttachment!.texture!.pixelFormat
        let (renderPipelineState, reflection) = try! device!.makeRenderPipelineState(descriptor: renderPipelineDescriptor, options: .bindingInfo)
        self.renderPipelineState = renderPipelineState
        self.reflection = reflection

        node.environmentValues[keyPath: \.renderPipelineState] = renderPipelineState
        node.environmentValues[keyPath: \.renderPipelineReflection] = reflection
    }

    func drawEnter() {
        renderCommandEncoder!.setRenderPipelineState(renderPipelineState!)
    }

    func drawExit() {
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
        print("drawEnter")
        try! encodeGeometry(renderCommandEncoder!)
    }

    func drawExit() {
        print("drawExit")
    }
}

public extension RenderPass {
    func parameter<T>(_ name: String, _ value: T) -> some RenderPass {
        ParameterRenderPass(name: name, value: value, content: self)
    }
}

struct ParameterRenderPass<Content, Value>: BodylessRenderPass where Content: RenderPass {
    var name: String
    var value: Value
    var content: Content

    @Environment(\.renderPipelineReflection)
    var reflection

    @Environment(\.renderCommandEncoder)
    var renderCommandEncoder

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

    func drawEnter() {
        print("HERE")

        let index = reflection!.binding(for: name)

        withUnsafeBytes(of: value) { buffer in
            renderCommandEncoder!.setFragmentBytes(buffer.baseAddress!, length: buffer.count, index: index)
        }
    }

    func drawExit() {
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

extension MTLRenderPipelineReflection {
    func binding(for name: String) -> Int {
        let indices = [vertexBindings.first { $0.name == name }?.index,
        fragmentBindings.first { $0.name == name }?.index,
        tileBindings.first { $0.name == name }?.index,
        objectBindings.first { $0.name == name }?.index,
        meshBindings.first { $0.name == name }?.index]
        .compactMap { $0 }
        if indices.isEmpty {
            fatalError("No binding for \(name)")
        }
        else if indices.count > 1 {
            fatalError("Ambiguous binding for \(name)")
        }
        return indices.first!
    }
}
