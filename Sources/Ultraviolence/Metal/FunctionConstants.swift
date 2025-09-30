import Metal
import UltraviolenceSupport

/// Type-safe wrapper for Metal function constant values
public struct FunctionConstants: Equatable {
    public enum Value: Equatable {
        case bool(Bool)
        case int8(Int8)
        case uint8(UInt8)
        case int16(Int16)
        case uint16(UInt16)
        case int32(Int32)
        case uint32(UInt32)
        case int64(Int64)
        case uint64(UInt64)
        case float(Float)
        case float2(SIMD2<Float>)
        case float3(SIMD3<Float>)
        case float4(SIMD4<Float>)
    }

    private var values: [String: Value] = [:]

    public init() {
        // Empty initializer
    }

    public var isEmpty: Bool {
        values.isEmpty
    }

    /// Get or set constant values by name using subscript
    public subscript(name: String) -> Value? {
        get { values[name] }
        set { values[name] = newValue }
    }

    /// Build MTLFunctionConstantValues
    public func buildMTLConstants(for library: MTLLibrary, functionName: String) throws -> MTLFunctionConstantValues {
        guard let baseFunction = library.makeFunction(name: functionName) else {
            try _throw(UltraviolenceError.configurationError("Function '\(functionName)' not found in library"))
        }

        let mtlConstants = MTLFunctionConstantValues()
        let constantsDictionary = baseFunction.functionConstantsDictionary

        for (name, value) in values {
            // If the constant name already has a namespace delimiter, use it as-is
            if name.contains("::") {
                if let info = constantsDictionary[name] {
                    value.apply(to: mtlConstants, at: info.index)
                } else if !constantsDictionary.isEmpty {
                    try _throw(UltraviolenceError.configurationError("Constant '\(name)' not found in function '\(functionName)'. Available: \(constantsDictionary.keys.joined(separator: ", "))"))
                }
            } else {
                // No namespace in the constant name - search for it
                // Try exact match first
                if let info = constantsDictionary[name] {
                    value.apply(to: mtlConstants, at: info.index)
                } else {
                    // Search for any constant ending with ::name
                    let matches = constantsDictionary.filter { $0.key.hasSuffix("::\(name)") }
                    if matches.count == 1, let info = matches.first?.value {
                        value.apply(to: mtlConstants, at: info.index)
                    } else if matches.count > 1 {
                        try _throw(UltraviolenceError.configurationError("Ambiguous constant '\(name)' in function '\(functionName)'. Multiple matches found: \(matches.keys.joined(separator: ", ")). Use fully qualified name."))
                    } else if !constantsDictionary.isEmpty {
                        try _throw(UltraviolenceError.configurationError("Constant '\(name)' not found in function '\(functionName)'. Available: \(constantsDictionary.keys.joined(separator: ", "))"))
                    }
                }
            }
            // If constantsDictionary is empty, skip silently (constant was optimized out)
        }

        return mtlConstants
    }
}

extension FunctionConstants.Value {
    var dataType: MTLDataType {
        switch self {
        case .bool: return .bool
        case .int8: return .char
        case .uint8: return .uchar
        case .int16: return .short
        case .uint16: return .ushort
        case .int32: return .int
        case .uint32: return .uint
        case .int64: return .long
        case .uint64: return .ulong
        case .float: return .float
        case .float2: return .float2
        case .float3: return .float3
        case .float4: return .float4
        }
    }

    /// Apply this constant value to MTLFunctionConstantValues at the specified index
    func apply(to constantValues: MTLFunctionConstantValues, at index: Int) {
        switch self {
        case .bool(let value):
            var mutableValue = value
            constantValues.setConstantValue(&mutableValue, type: .bool, index: index)
        case .int8(let value):
            var mutableValue = value
            constantValues.setConstantValue(&mutableValue, type: .char, index: index)
        case .uint8(let value):
            var mutableValue = value
            constantValues.setConstantValue(&mutableValue, type: .uchar, index: index)
        case .int16(let value):
            var mutableValue = value
            constantValues.setConstantValue(&mutableValue, type: .short, index: index)
        case .uint16(let value):
            var mutableValue = value
            constantValues.setConstantValue(&mutableValue, type: .ushort, index: index)
        case .int32(let value):
            var mutableValue = value
            constantValues.setConstantValue(&mutableValue, type: .int, index: index)
        case .uint32(let value):
            var mutableValue = value
            constantValues.setConstantValue(&mutableValue, type: .uint, index: index)
        case .int64(let value):
            var mutableValue = value
            constantValues.setConstantValue(&mutableValue, type: .long, index: index)
        case .uint64(let value):
            var mutableValue = value
            constantValues.setConstantValue(&mutableValue, type: .ulong, index: index)
        case .float(let value):
            var mutableValue = value
            constantValues.setConstantValue(&mutableValue, type: .float, index: index)
        case .float2(let value):
            var mutableValue = value
            constantValues.setConstantValue(&mutableValue, type: .float2, index: index)
        case .float3(let value):
            var mutableValue = value
            constantValues.setConstantValue(&mutableValue, type: .float3, index: index)
        case .float4(let value):
            var mutableValue = value
            constantValues.setConstantValue(&mutableValue, type: .float4, index: index)
        }
    }
}
