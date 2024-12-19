import struct SwiftUI.Color
import CoreGraphics
import Metal
import simd
import UltraviolenceSupport

internal struct ParameterRenderPass<Content, T>: BodylessRenderPass where Content: RenderPass {
    var name: String

    var functionType: MTLFunctionType?
    var value: ParameterValue<T>
    var content: Content

    @Environment(\.reflection)
    var reflection

    @Environment(\.renderCommandEncoder)
    var renderCommandEncoder

    @Environment(\.computeCommandEncoder)
    var computeCommandEncoder

    internal init(functionType: MTLFunctionType? = nil, name: String, value: ParameterValue<T>, content: Content) {
        self.functionType = functionType
        self.name = name
        self.value = value
        self.content = content
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

    func drawEnter() throws {
        guard let reflection else {
            fatalError("No reflection environment found.")
        }
        if let renderCommandEncoder {
            if let functionType {
                let index = try reflection.binding(forType: functionType, name: name).orThrow(.missingBinding(name))
                renderCommandEncoder.setValue(value, index: index, functionType: functionType)
            }
            else {
                let vertexIndex = reflection.binding(forType: .vertex, name: name)
                let fragmentIndex = reflection.binding(forType: .fragment, name: name)
                switch (vertexIndex, fragmentIndex) {
                case (.some(let vertexIndex), .some(let fragmentIndex)):
                    fatalError("Ambiguous parameter, found parameter named \(name) in both vertex (index: #\(vertexIndex)) and fragment (index: #\(fragmentIndex)) shaders.")
                case (.some(let vertexIndex), .none):
                    renderCommandEncoder.setValue(value, index: vertexIndex, functionType: .vertex)
                case (.none, .some(let fragmentIndex)):
                    renderCommandEncoder.setValue(value, index: fragmentIndex, functionType: .fragment)
                case (.none, .none):
                    throw UltraviolenceError.missingBinding(name)
                }
            }
        }
    }
}

// MARK: -

public extension RenderPass {
    // TODO: Add MTLFunctionType to all of these.
    func parameter(_ name: String, _ value: SIMD4<Float>, functionType: MTLFunctionType? = nil) -> some RenderPass {
        ParameterRenderPass(functionType: functionType, name: name, value: .value(value), content: self)
    }

    func parameter(_ name: String, _ value: simd_float4x4, functionType: MTLFunctionType? = nil) -> some RenderPass {
        ParameterRenderPass(functionType: functionType, name: name, value: .value(value), content: self)
    }

    func parameter(_ name: String, _ value: Color, functionType: MTLFunctionType? = nil) -> some RenderPass {
        let colorspace = CGColorSpaceCreateDeviceRGB()
        guard let color = value.resolve(in: .init()).cgColor.converted(to: colorspace, intent: .defaultIntent, options: nil) else {
            fatalError("Unimplemented.")
        }
        guard let components = color.components?.map({ Float($0) }) else {
            fatalError("Unimplemented.")
        }
        let value = SIMD4<Float>(components[0], components[1], components[2], components[3])
        return ParameterRenderPass(functionType: functionType, name: name, value: .value(value), content: self)
    }

    func parameter(_ name: String, _ texture: MTLTexture, functionType: MTLFunctionType? = nil) -> some RenderPass {
        ParameterRenderPass(functionType: functionType, name: name, value: ParameterValue<()>.texture(texture), content: self)
    }

    func parameter(_ name: String, _ buffer: MTLBuffer, offset: Int, functionType: MTLFunctionType? = nil) -> some RenderPass {
        ParameterRenderPass(functionType: functionType, name: name, value: ParameterValue<()>.buffer(buffer, offset), content: self)
    }

    func parameter(_ name: String, _ value: some Any, functionType: MTLFunctionType? = nil) -> some RenderPass {
        ParameterRenderPass(functionType: functionType, name: name, value: .value(value), content: self)
    }

    func parameter<T>(_ name: String, _ value: [some Any], functionType: MTLFunctionType? = nil) -> some RenderPass {
        ParameterRenderPass(functionType: functionType, name: name, value: .array(value), content: self)
    }
}

// MARK: -
