import struct SwiftUI.Color
import CoreGraphics
import Metal
import simd
import UltraviolenceSupport

internal struct ParameterElement<Content, T>: Element, BodylessElement, BodylessContentElement where Content: Element {
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

    func workloadEnter(_ node: Node) throws {
        let reflection = try node.environmentValues.reflection.orThrow(.missingEnvironment(\.reflection))
        let renderCommandEncoder = node.environmentValues.renderCommandEncoder
        let computeCommandEncoder = node.environmentValues.computeCommandEncoder

        // TODO: #51 We can be a lot better about logging errors here.
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
                    preconditionFailure("Ambiguous parameter, found parameter named \(name) in both vertex (index: #\(vertexIndex)) and fragment (index: #\(fragmentIndex)) shaders.")

                case (.some(let vertexIndex), .none):
                    renderCommandEncoder.setValue(value, index: vertexIndex, functionType: .vertex)

                case (.none, .some(let fragmentIndex)):
                    renderCommandEncoder.setValue(value, index: fragmentIndex, functionType: .fragment)

                case (.none, .none):
                    logger?.info("Parameter \(name) not found in reflection \(reflection.debugDescription).")
                    throw UltraviolenceError.missingBinding(name)
                }
            }

        case (nil, .some(let computeCommandEncoder)):
            precondition(functionType == nil || functionType == .kernel)
            let index = try reflection.binding(forType: .kernel, name: name).orThrow(.missingBinding(name))
            computeCommandEncoder.setValue(value, index: index)

        case (.some, .some):
            preconditionFailure("Trying to process \(self) with both a render command encoder and a compute command encoder.")

        default:
            preconditionFailure("Trying to process `\(self) without a command encoder.")
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
            preconditionFailure("Unimplemented.")
        }
        guard let components = color.components?.map({ Float($0) }) else {
            preconditionFailure("Unimplemented.")
        }
        let value = SIMD4<Float>(components[0], components[1], components[2], components[3])
        return ParameterElement(functionType: functionType, name: name, value: .value(value), content: self)
    }

    func parameter(_ name: String, texture: MTLTexture, functionType: MTLFunctionType? = nil) -> some Element {
        ParameterElement(functionType: functionType, name: name, value: ParameterValue<()>.texture(texture), content: self)
    }

    func parameter(_ name: String, samplerState: MTLSamplerState, functionType: MTLFunctionType? = nil) -> some Element {
        ParameterElement(functionType: functionType, name: name, value: ParameterValue<()>.samplerState(samplerState), content: self)
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
