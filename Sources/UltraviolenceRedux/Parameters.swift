import struct SwiftUI.Color
import CoreGraphics

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

public extension RenderPass {
    func parameter(_ name: String, _ value: SIMD4<Float>) -> some RenderPass {
        ParameterRenderPass(name: name, value: value, content: self)
    }

    func parameter(_ name: String, _ value: Color) -> some RenderPass {
        let colorspace = CGColorSpaceCreateDeviceRGB()
        let color = value.resolve(in: .init()).cgColor.converted(to: colorspace, intent: .defaultIntent, options: nil)!
        let components = color.components!.map { Float($0) }
        let value = SIMD4<Float>(components[0], components[1], components[2], components[3])
        return ParameterRenderPass(name: name, value: value, content: self)
    }

    func parameter<T>(_ name: String, _ value: T) -> some RenderPass {
        ParameterRenderPass(name: name, value: value, content: self)
    }
}
