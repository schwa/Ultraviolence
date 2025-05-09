import Metal

internal enum ParameterValue<T> {
    case texture(MTLTexture?)
    case samplerState(MTLSamplerState?)
    case buffer(MTLBuffer?, Int)
    case array([T])
    case value(T)
}

extension ParameterValue: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case .texture(let texture):
            return "Texture"
        case .samplerState(let samplerState):
            return "SamplerState"
        case .buffer(let buffer, let offset):
            return "Buffer(\(String(describing: buffer?.label)), offset: \(offset)"
        case .array(let array):
            return "Array"
        case .value(let value):
            return "\(value)"
        }
    }
}

// TODO: #21 We really need to rethink type safety of ParameterValue. Make this a struct and keep internal enum - still need to worry about <T> though.
// extension ParameterValue where T == () {
//    static func texture(_ texture: MTLTexture) -> ParameterValue {
//        .texture(texture) // Error. Ambiguous use of 'texture'.
//    }
// }

internal extension MTLRenderCommandEncoder {
    func setValue<T>(_ value: ParameterValue<T>, index: Int, functionType: MTLFunctionType) {
        switch value {
        case .texture(let texture):
            setTexture(texture, index: index, functionType: functionType)

        case .samplerState(let samplerState):
            setSamplerState(samplerState, index: index, functionType: functionType)

        case .buffer(let buffer, let offset):
            setBuffer(buffer, offset: offset, index: index, functionType: functionType)

        case .array(let array):
            setUnsafeBytes(of: array, index: index, functionType: functionType)

        case .value(let value):
            setUnsafeBytes(of: value, index: index, functionType: functionType)
        }
    }
}

internal extension MTLComputeCommandEncoder {
    func setValue<T>(_ value: ParameterValue<T>, index: Int) {
        switch value {
        case .texture(let texture):
            setTexture(texture, index: index)

        case .samplerState(let samplerState):
            setSamplerState(samplerState, index: index)

        case .buffer(let buffer, let offset):
            setBuffer(buffer, offset: offset, index: index)

        case .array(let array):
            setUnsafeBytes(of: array, index: index)

        case .value(let value):
            setUnsafeBytes(of: value, index: index)
        }
    }
}

// MARK: -

internal struct AnyParameterValue {
    var renderSetValue: (MTLRenderCommandEncoder, Int, MTLFunctionType) -> Void
    var computeSetValue: (MTLComputeCommandEncoder, Int) -> Void
    var _debugDescription: () -> String

    init<T>(_ value: ParameterValue<T>) {
        self.renderSetValue = { encoder, index, functionType in
            encoder.setValue(value, index: index, functionType: functionType)
        }
        self.computeSetValue = { encoder, index in
            encoder.setValue(value, index: index)
        }
        self._debugDescription = {
            value.debugDescription
        }
    }
}

extension AnyParameterValue: CustomDebugStringConvertible {
    var debugDescription: String {
        _debugDescription()
    }
}

internal extension MTLRenderCommandEncoder {
    func setValue(_ value: AnyParameterValue, index: Int, functionType: MTLFunctionType) {
        value.renderSetValue(self, index, functionType)
    }
}

internal extension MTLComputeCommandEncoder {
    func setValue(_ value: AnyParameterValue, index: Int) {
        value.computeSetValue(self, index)
    }
}
