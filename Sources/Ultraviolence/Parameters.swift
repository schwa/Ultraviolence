import struct SwiftUI.Color
import CoreGraphics
import Metal
import simd
import UltraviolenceSupport

internal struct ParameterElement<Content, T>: BodylessElement where Content: Element {
    var name: String

    var functionType: MTLFunctionType?
    var value: ParameterValue<T>
    var content: Content

    internal init(functionType: MTLFunctionType? = nil, name: String, value: ParameterValue<T>, content: Content) {
        self.functionType = functionType
        self.name = name
        self.value = value
        self.content = content
    }

    func _expandNode(_ node: Node) throws {
        // TODO: Move into BodylessRenderPass
        guard let graph = node.graph else {
            fatalError("Cannot build node tree without a graph.")
        }
        if node.children.isEmpty {
            node.children.append(graph.makeNode())
        }
        try content.expandNode(node.children[0])
    }

    func _enter(_ node: Node, environment: inout EnvironmentValues) throws {
        let reflection = try environment.reflection.orThrow(.missingEnvironment(\.reflection))
        let renderCommandEncoder = environment.renderCommandEncoder
        let computeCommandEncoder = environment.computeCommandEncoder

        switch (renderCommandEncoder, computeCommandEncoder) {
        case (.some(let renderCommandEncoder), nil):
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
        case (nil, .some(let computeCommandEncoder)):
            precondition(functionType == nil || functionType == .kernel)
            let index = try reflection.binding(forType: .kernel, name: name).orThrow(.missingBinding(name))
            computeCommandEncoder.setValue(value, index: index, functionType: .kernel)
        case (.some, .some):
            fatalError("Trying to process \(self.shortDescription) with both a render command encoder and a compute command encoder.")
        default:
            fatalError("Trying to process `\(self.shortDescription) without a command encoder.")
        }
    }
}

// MARK: -

public extension Element {
    func parameter(_ name: String, _ value: SIMD4<Float>, functionType: MTLFunctionType? = nil) -> some Element {
        ParameterElement(functionType: functionType, name: name, value: .value(value), content: self)
    }

    func parameter(_ name: String, _ value: simd_float4x4, functionType: MTLFunctionType? = nil) -> some Element {
        ParameterElement(functionType: functionType, name: name, value: .value(value), content: self)
    }

    func parameter(_ name: String, color: Color, functionType: MTLFunctionType? = nil) -> some Element {
        let colorspace = CGColorSpaceCreateDeviceRGB()
        guard let color = color.resolve(in: .init()).cgColor.converted(to: colorspace, intent: .defaultIntent, options: nil) else {
            fatalError("Unimplemented.")
        }
        guard let components = color.components?.map({ Float($0) }) else {
            fatalError("Unimplemented.")
        }
        let value = SIMD4<Float>(components[0], components[1], components[2], components[3])
        return ParameterElement(functionType: functionType, name: name, value: .value(value), content: self)
    }

    func parameter(_ name: String, texture: MTLTexture, functionType: MTLFunctionType? = nil) -> some Element {
        ParameterElement(functionType: functionType, name: name, value: ParameterValue<()>.texture(texture), content: self)
    }

    func parameter(_ name: String, buffer: MTLBuffer, offset: Int = 0, functionType: MTLFunctionType? = nil) -> some Element {
        ParameterElement(functionType: functionType, name: name, value: ParameterValue<()>.buffer(buffer, offset), content: self)
    }

    func parameter(_ name: String, values: [some Any], functionType: MTLFunctionType? = nil) -> some Element {
        ParameterElement(functionType: functionType, name: name, value: .array(values), content: self)
    }

    func parameter(_ name: String, value: some Any, functionType: MTLFunctionType? = nil) -> some Element {
        ParameterElement(functionType: functionType, name: name, value: .value(value), content: self)
    }
}

// MARK: -
