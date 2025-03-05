import struct SwiftUI.Color
import CoreGraphics
import Metal
import simd
import UltraviolenceSupport

// TODO: #62 instead of being typed <T> we need an "AnyParameter" and this needs to take a dictionary of AnyParameters
// TODO: Rename it to be a modifier?
internal struct ParameterElement<Content>: Element, BodylessElement, BodylessContentElement where Content: Element {
    var parameters: [String: Parameter]
    var content: Content

    internal init<T>(functionType: MTLFunctionType? = nil, name: String, value: ParameterValue<T>, content: Content) {
        self.parameters = [name: .init(name: name, functionType: functionType, value: value)]
        self.content = content
    }

    func workloadEnter(_ node: Node) throws {
        let reflection = try node.environmentValues.reflection.orThrow(.missingEnvironment(\.reflection))
        let renderCommandEncoder = node.environmentValues.renderCommandEncoder
        let computeCommandEncoder = node.environmentValues.computeCommandEncoder
        for parameter in parameters.values {
            switch (renderCommandEncoder, computeCommandEncoder) {
            case (.some(let renderCommandEncoder), nil):
                try parameter.set(on: renderCommandEncoder, reflection: reflection)
            case (nil, .some(let computeCommandEncoder)):
                try parameter.set(on: computeCommandEncoder, reflection: reflection)
            case (.some, .some):
                preconditionFailure("Trying to process \(self) with both a render command encoder and a compute command encoder.")
            default:
                preconditionFailure("Trying to process `\(self) without a command encoder.")
            }
        }
    }
}

// MARK: -

internal struct Parameter {
    var name: String
    var functionType: MTLFunctionType?
    var value: AnyParameterValue

    init<T>(name: String, functionType: MTLFunctionType? = nil, value: ParameterValue<T>) {
        self.name = name
        self.functionType = functionType
        self.value = AnyParameterValue(value)
    }

    @MainActor
    func set(on encoder: MTLRenderCommandEncoder, reflection: Reflection) throws {
        switch functionType {
        case .vertex:
            if let index = try reflection.binding(forType: .vertex, name: name) {
                encoder.setValue(value, index: index, functionType: .vertex)
            }
        case .fragment:
            if let index = try reflection.binding(forType: .fragment, name: name) {
                encoder.setValue(value, index: index, functionType: .fragment)
            }
        case nil:
            let vertexIndex = reflection.binding(forType: .vertex, name: name)
            let fragmentIndex = reflection.binding(forType: .fragment, name: name)
            switch (vertexIndex, fragmentIndex) {
            case (.some(let vertexIndex), .some(let fragmentIndex)):
                preconditionFailure("Ambiguous parameter, found parameter named \(name) in both vertex (index: #\(vertexIndex)) and fragment (index: #\(fragmentIndex)) shaders.")
            case (.some(let vertexIndex), .none):
                encoder.setValue(value, index: vertexIndex, functionType: .vertex)
            case (.none, .some(let fragmentIndex)):
                encoder.setValue(value, index: fragmentIndex, functionType: .fragment)
            case (.none, .none):
                logger?.info("Parameter \(name) not found in reflection \(reflection.debugDescription).")
                throw UltraviolenceError.missingBinding(name)
            }
        default:
            fatalError()
        }
    }

    func set(on encoder: MTLComputeCommandEncoder, reflection: Reflection) throws {
        guard functionType == .kernel || functionType == nil else {
            throw UltraviolenceError.generic("Invalid function type \(functionType.debugDescription).")
        }
        let index = try reflection.binding(forType: .kernel, name: name).orThrow(.missingBinding(name))
        encoder.setValue(value, index: index)
    }
}

// MARK: -

public extension Element {
    // TODO: Move functionType to front of the parameter list
    func parameter(_ name: String, _ value: SIMD4<Float>, functionType: MTLFunctionType? = nil) -> some Element {
        ParameterElement(functionType: functionType, name: name, value: .value(value), content: self)
    }

    func parameter(_ name: String, _ value: simd_float4x4, functionType: MTLFunctionType? = nil) -> some Element {
        ParameterElement(functionType: functionType, name: name, value: .value(value), content: self)
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
        assert(isPODArray(values), "Parameter values must be a POD type.")
        return ParameterElement(functionType: functionType, name: name, value: .array(values), content: self)
    }

    func parameter(_ name: String, value: some Any, functionType: MTLFunctionType? = nil) -> some Element {
        assert(isPOD(value), "Parameter value must be a POD type.")
        return ParameterElement(functionType: functionType, name: name, value: .value(value), content: self)
    }
}

// TODO: Move out of here. All SwiftUI stuff needs to be quarantined.
// Also it could take a SwiftUI environment()
// Also SRGB?
public extension Element {
    func parameter(_ name: String, color: Color, functionType: MTLFunctionType? = nil) -> some Element {
        let colorspace = CGColorSpaceCreateDeviceRGB()
        guard let color = color.resolve(in: .init()).cgColor.converted(to: colorspace, intent: .defaultIntent, options: nil) else {
            preconditionFailure("Unimplemented.")
        }
        guard let components = color.components?.map({ Float($0) }) else {
            preconditionFailure("Unimplemented.")
        }
        let value = SIMD4<Float>(components[0], components[1], components[2], components[3])
        return parameter(name, value, functionType: functionType)
    }
}
