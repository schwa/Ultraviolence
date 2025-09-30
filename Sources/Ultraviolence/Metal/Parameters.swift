import CoreGraphics
import Metal
import simd
import UltraviolenceSupport

// TODO: #62 instead of being typed <T> we need an "AnyParameter" and this needs to take a dictionary of AnyParameters
internal struct ParameterElementModifier<Content>: Element, BodylessElement, BodylessContentElement where Content: Element {
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

    nonisolated func requiresSetup(comparedTo old: ParameterElementModifier<Content>) -> Bool {
        // Parameter values changing never requires setup - they're only used in workload phase
        false
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
        try encoder.withDebugGroup("MTLRenderCommandEncoder(\(encoder.label.quoted)): \(name.quoted) = \(value)") {
            switch functionType {
            case .vertex:
                if let index = reflection.binding(forType: .vertex, name: name) {
                    encoder.setValue(value, index: index, functionType: .vertex)
                }
            case .fragment:
                if let index = reflection.binding(forType: .fragment, name: name) {
                    encoder.setValue(value, index: index, functionType: .fragment)
                }
            case nil:
                let vertexIndex = reflection.binding(forType: .vertex, name: name)
                let fragmentIndex = reflection.binding(forType: .fragment, name: name)
                switch (vertexIndex, fragmentIndex) {
                case let (.some(vertexIndex), .some(fragmentIndex)):
                    preconditionFailure("Ambiguous parameter, found parameter named \(name) in both vertex (index: #\(vertexIndex)) and fragment (index: #\(fragmentIndex)) shaders.")
                case (.some(let vertexIndex), .none):
                    encoder.setValue(value, index: vertexIndex, functionType: .vertex)
                case (.none, .some(let fragmentIndex)):
                    encoder.setValue(value, index: fragmentIndex, functionType: .fragment)
                case (.none, .none):
                    logger?.info("Parameter \(name) not found in reflection \(reflection.debugDescription).")
                    try _throw(UltraviolenceError.missingBinding(name))
                }
            default:
                fatalError("Invalid shader type \(functionType.debugDescription).")
            }
        }
    }

    func set(on encoder: MTLComputeCommandEncoder, reflection: Reflection) throws {
        guard functionType == .kernel || functionType == nil else {
            try _throw(UltraviolenceError.configurationError("Invalid function type \(functionType.debugDescription)."))
        }
        let index = try reflection.binding(forType: .kernel, name: name).orThrow(.missingBinding(name))
        encoder.setValue(value, index: index)
    }
}

// MARK: -

public extension Element {
    func parameter(_ name: String, functionType: MTLFunctionType? = nil, value: SIMD4<Float>) -> some Element {
        ParameterElementModifier(functionType: functionType, name: name, value: .value(value), content: self)
    }

    func parameter(_ name: String, functionType: MTLFunctionType? = nil, value: simd_float4x4) -> some Element {
        ParameterElementModifier(functionType: functionType, name: name, value: .value(value), content: self)
    }

    func parameter(_ name: String, functionType: MTLFunctionType? = nil, texture: MTLTexture?) -> some Element {
        ParameterElementModifier(functionType: functionType, name: name, value: ParameterValue<()>.texture(texture), content: self)
    }

    func parameter(_ name: String, functionType: MTLFunctionType? = nil, samplerState: MTLSamplerState) -> some Element {
        ParameterElementModifier(functionType: functionType, name: name, value: ParameterValue<()>.samplerState(samplerState), content: self)
    }

    func parameter(_ name: String, functionType: MTLFunctionType? = nil, buffer: MTLBuffer, offset: Int = 0) -> some Element {
        ParameterElementModifier(functionType: functionType, name: name, value: ParameterValue<()>.buffer(buffer, offset), content: self)
    }

    func parameter(_ name: String, functionType: MTLFunctionType? = nil, values: [some Any]) -> some Element {
        assert(isPODArray(values), "Parameter values must be a POD type.")
        return ParameterElementModifier(functionType: functionType, name: name, value: .array(values), content: self)
    }

    func parameter(_ name: String, functionType: MTLFunctionType? = nil, value: some Any) -> some Element {
        assert(isPOD(value), "Parameter value must be a POD type.")
        return ParameterElementModifier(functionType: functionType, name: name, value: .value(value), content: self)
    }
}

extension String {
    var quoted: String {
        "\"\(self)\""
    }
}

extension Optional<String> {
    var quoted: String {
        switch self {
        case .none:
            return "nil"
        case .some(let string):
            return string.quoted
        }
    }
}
