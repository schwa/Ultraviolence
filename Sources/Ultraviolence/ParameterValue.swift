import Metal

internal enum ParameterValue<T> {
    case texture(MTLTexture)
    case samplerState(MTLSamplerState)
    case buffer(MTLBuffer, Int)
    case array([T])
    case value(T)
}

// TODO: We really need to rethink type safety of ParameterValue. Make this a struct and keep internal enum - still need to worry about <T> though. https://github.com/schwa/Ultraviolence/issues/21
// extension ParameterValue where T == () {
//    static func texture(_ texture: MTLTexture) -> ParameterValue {
//        .texture(texture) // TODO: Error. Ambiguous use of 'texture'.
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
            setBuffer(buffer, offset: offset, index: index) // TODO: OFFSET
        case .array(let array):
            setUnsafeBytes(of: array, index: index)
        case .value(let value):
            setUnsafeBytes(of: value, index: index)
        }
    }
}
