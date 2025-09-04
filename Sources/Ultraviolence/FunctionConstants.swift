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
    
    public init() {}
    
    /// Get or set constant values by name using subscript
    public subscript(name: String) -> Value? {
        get { values[name] }
        set { values[name] = newValue }
    }
    
    /// Build MTLFunctionConstantValues using shader introspection to get indices
    public func buildMTLConstants(for library: MTLLibrary, functionName: String) throws -> MTLFunctionConstantValues {
        let mtlConstants = MTLFunctionConstantValues()
        
        // Get the function's constant dictionary to map names to indices
        guard let functionDescriptor = library.functionNames.contains(functionName) ? library.makeFunction(name: functionName) : nil else {
            throw UltraviolenceError.generic("Function '\(functionName)' not found in library")
        }
        
        // Apply each constant value using the function's constant dictionary
        for (name, value) in values {
            if let constantInfo = functionDescriptor.functionConstantsDictionary[name] {
                value.apply(to: mtlConstants, at: constantInfo.index)
            }
        }
        
        return mtlConstants
    }
    
    /// Build MTLFunctionConstantValues when indices are already known
    public func buildMTLConstants(with indices: [String: Int]) -> MTLFunctionConstantValues {
        let mtlConstants = MTLFunctionConstantValues()
        
        for (name, value) in values {
            if let index = indices[name] {
                value.apply(to: mtlConstants, at: index)
            }
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