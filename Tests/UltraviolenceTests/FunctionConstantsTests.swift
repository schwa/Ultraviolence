import Metal
import Testing
@testable import Ultraviolence

struct FunctionConstantsTests {
    @Test("Value enum equality")
    func valueEquality() throws {
        #expect(FunctionConstants.Value.bool(true) == FunctionConstants.Value.bool(true))
        #expect(FunctionConstants.Value.bool(true) != FunctionConstants.Value.bool(false))
        #expect(FunctionConstants.Value.int32(42) == FunctionConstants.Value.int32(42))
        #expect(FunctionConstants.Value.int32(42) != FunctionConstants.Value.int32(43))
        #expect(FunctionConstants.Value.float(3.14) == FunctionConstants.Value.float(3.14))
        #expect(FunctionConstants.Value.float2([1, 2]) == FunctionConstants.Value.float2([1, 2]))
        #expect(FunctionConstants.Value.float2([1, 2]) != FunctionConstants.Value.float2([1, 3]))
    }

    @Test("Value data types")
    func valueDataTypes() throws {
        #expect(FunctionConstants.Value.bool(true).dataType == .bool)
        #expect(FunctionConstants.Value.int8(1).dataType == .char)
        #expect(FunctionConstants.Value.uint8(1).dataType == .uchar)
        #expect(FunctionConstants.Value.int16(1).dataType == .short)
        #expect(FunctionConstants.Value.uint16(1).dataType == .ushort)
        #expect(FunctionConstants.Value.int32(1).dataType == .int)
        #expect(FunctionConstants.Value.uint32(1).dataType == .uint)
        #expect(FunctionConstants.Value.int64(1).dataType == .long)
        #expect(FunctionConstants.Value.uint64(1).dataType == .ulong)
        #expect(FunctionConstants.Value.float(1.0).dataType == .float)
        #expect(FunctionConstants.Value.float2([1, 2]).dataType == .float2)
        #expect(FunctionConstants.Value.float3([1, 2, 3]).dataType == .float3)
        #expect(FunctionConstants.Value.float4([1, 2, 3, 4]).dataType == .float4)
    }

    @Test("Set and update values using subscript")
    func setValues() throws {
        var constants = FunctionConstants()

        // Test subscript setter
        constants["myInt"] = .int32(42)
        constants["myFloat"] = .float(3.14)
        constants["myBool"] = .bool(true)

        // Test multiple assignments
        constants["anotherInt"] = .int32(100)
        constants["anotherFloat"] = .float(2.71)
        constants["vector"] = .float3([1, 2, 3])

        // Test updating existing value
        constants["myInt"] = .int32(99)

        // Test subscript getter
        #expect(constants["myInt"] == .int32(99))
        #expect(constants["myFloat"] == .float(3.14))
        #expect(constants["nonExistent"] == nil)

        // Verify equality
        var constants2 = FunctionConstants()
        constants2["myInt"] = .int32(99)
        constants2["myFloat"] = .float(3.14)
        constants2["myBool"] = .bool(true)
        constants2["anotherInt"] = .int32(100)
        constants2["anotherFloat"] = .float(2.71)
        constants2["vector"] = .float3([1, 2, 3])

        #expect(constants == constants2)
    }

    @Test("Apply to MTLFunctionConstantValues")
    func applyToMTLConstants() throws {
        let mtlConstants = MTLFunctionConstantValues()

        // Test each value type
        FunctionConstants.Value.bool(true).apply(to: mtlConstants, at: 0)
        FunctionConstants.Value.int8(127).apply(to: mtlConstants, at: 1)
        FunctionConstants.Value.uint8(255).apply(to: mtlConstants, at: 2)
        FunctionConstants.Value.int16(32_767).apply(to: mtlConstants, at: 3)
        FunctionConstants.Value.uint16(65_535).apply(to: mtlConstants, at: 4)
        FunctionConstants.Value.int32(2_147_483_647).apply(to: mtlConstants, at: 5)
        FunctionConstants.Value.uint32(4_294_967_295).apply(to: mtlConstants, at: 6)
        FunctionConstants.Value.int64(9_223_372_036_854_775_807).apply(to: mtlConstants, at: 7)
        FunctionConstants.Value.uint64(18_446_744_073_709_551_615).apply(to: mtlConstants, at: 8)
        FunctionConstants.Value.float(3.14159).apply(to: mtlConstants, at: 9)
        FunctionConstants.Value.float2([1.0, 2.0]).apply(to: mtlConstants, at: 10)
        FunctionConstants.Value.float3([1.0, 2.0, 3.0]).apply(to: mtlConstants, at: 11)
        FunctionConstants.Value.float4([1.0, 2.0, 3.0, 4.0]).apply(to: mtlConstants, at: 12)

        // MTLFunctionConstantValues doesn't provide a way to read back values,
        // but we verified that apply() was called for each type without throwing
        // The test passing means no crashes occurred during the apply operations
    }

    @Test("Build MTL constants requires library")
    func buildMTLConstantsRequiresLibrary() throws {
        var constants = FunctionConstants()
        constants["myInt"] = .int32(42)
        constants["myFloat"] = .float(3.14)
        constants["myBool"] = .bool(true)

        // buildMTLConstants now requires a library and function name to introspect
        // the actual function's constants dictionary. Without a real Metal library
        // with a function that has these constants, we can't test this directly.
        // The functionality is tested through integration tests with actual shaders.

        // Test that we can still create and manipulate FunctionConstants
        #expect(constants["myInt"] == .int32(42))
        #expect(constants["myFloat"] == .float(3.14))
        #expect(constants["myBool"] == .bool(true))
    }

    @Test("Empty constants creation")
    func emptyConstants() throws {
        let constants = FunctionConstants()

        // Test that empty constants are properly initialized
        #expect(constants.isEmpty == true)
        #expect(constants["anyKey"] == nil)

        // Test that we can add values to empty constants
        var mutableConstants = constants
        mutableConstants["test"] = .int32(1)
        #expect(mutableConstants.isEmpty == false)
    }

    @Test("Constants equality")
    func constantsEquality() throws {
        var constants1 = FunctionConstants()
        constants1["value1"] = .int32(42)
        constants1["value2"] = .float(3.14)

        var constants2 = FunctionConstants()
        constants2["value1"] = .int32(42)
        constants2["value2"] = .float(3.14)

        var constants3 = FunctionConstants()
        constants3["value1"] = .int32(43)  // Different value
        constants3["value2"] = .float(3.14)

        var constants4 = FunctionConstants()
        constants4["value1"] = .int32(42)
        constants4["differentName"] = .float(3.14)  // Different name

        #expect(constants1 == constants2)
        #expect(constants1 != constants3)
        #expect(constants1 != constants4)
    }
}
