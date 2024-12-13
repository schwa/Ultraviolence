import struct SwiftUI.Color
import CoreGraphics
import simd
import UltraviolenceSupport

internal struct ParameterRenderPass<Content, Value>: BodylessRenderPass where Content: RenderPass {
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

    func drawEnter() throws {
        let (type, index) = try reflection.orThrow(.missingBinding(name)).binding(for: name)

        try withUnsafeBytes(of: value) { buffer in
            let renderCommandEncoder = try renderCommandEncoder.orThrow(.missingEnvironment("renderCommandEncoder"))
            let baseAddress = try buffer.baseAddress.orThrow(.resourceCreationFailure)
            switch type {
            case .fragment:
                renderCommandEncoder.setFragmentBytes(baseAddress, length: buffer.count, index: index)
            case .vertex:
                renderCommandEncoder.setVertexBytes(baseAddress, length: buffer.count, index: index)
            default:
                fatalError("Unimplemented.")
            }
        }
    }
}

public extension RenderPass {
    func parameter(_ name: String, _ value: SIMD4<Float>) -> some RenderPass {
        ParameterRenderPass(name: name, value: value, content: self)
    }

    func parameter(_ name: String, _ value: simd_float4x4) -> some RenderPass {
        ParameterRenderPass(name: name, value: value, content: self)
    }

    func parameter(_ name: String, _ value: Color) -> some RenderPass {
        let colorspace = CGColorSpaceCreateDeviceRGB()
        guard let color = value.resolve(in: .init()).cgColor.converted(to: colorspace, intent: .defaultIntent, options: nil) else {
            fatalError("Unimplemented.")
        }
        guard let components = color.components?.map({ Float($0) }) else {
            fatalError("Unimplemented.")
        }
        let value = SIMD4<Float>(components[0], components[1], components[2], components[3])
        return ParameterRenderPass(name: name, value: value, content: self)
    }

    func parameter<T>(_ name: String, _ value: T) -> some RenderPass {
        ParameterRenderPass(name: name, value: value, content: self)
    }
}
