import Testing
@testable import Ultraviolence

struct TestEnvironmentKey: UVEnvironmentKey {
    static let defaultValue = "default"
}

extension UVEnvironmentValues {
    var testValue: String {
        get { self[TestEnvironmentKey.self] }
        set { self[TestEnvironmentKey.self] = newValue }
    }
}

@Suite struct UVEnvironmentValuesStorageTests {
    @Test func testNormalParentChain() {
        let storage1 = UVEnvironmentValues.Storage()
        storage1.values[.init(TestEnvironmentKey.self)] = "value1"

        let storage2 = UVEnvironmentValues.Storage()
        storage2.parent = storage1
        storage2.values[.init(TestEnvironmentKey.self)] = "value2"

        let storage3 = UVEnvironmentValues.Storage()
        storage3.parent = storage2

        #expect(storage3[.init(TestEnvironmentKey.self)] as? String == "value2")
    }

    @Test(.disabled("Would trigger assertion - demonstrates self-cycle protection"))
    func testDirectSelfCycle() {
        let storage = UVEnvironmentValues.Storage()
        storage.values[.init(TestEnvironmentKey.self)] = "value"

        // This would trigger assertion: "Cannot set Storage parent to itself"
        // storage.parent = storage
    }

    @Test func testTwoNodeCyclePrevention() {
        let storage1 = UVEnvironmentValues.Storage()
        storage1.values[.init(TestEnvironmentKey.self)] = "value1"

        let storage2 = UVEnvironmentValues.Storage()
        storage2.parent = storage1

        // This should trigger assertion in debug builds - cannot create cycle
        // In release builds, the assertion won't fire but we still prevent the cycle
        #if DEBUG
        // We can't directly test assertions, but document the expected behavior
        // storage1.parent = storage2 // Would assert: "Cannot set parent - would create a cycle"
        #endif
    }

    @Test func testParentChainDepth() {
        // Test that we can have reasonable depth without issues
        var storages: [UVEnvironmentValues.Storage] = []
        for i in 0..<10 {
            let storage = UVEnvironmentValues.Storage()
            storage.values[.init(TestEnvironmentKey.self)] = "value\(i)"
            if i > 0 {
                storage.parent = storages[i - 1]
            }
            storages.append(storage)
        }

        // Should find value from parent chain
        let lastStorage = storages.last!
        #expect(lastStorage[.init(TestEnvironmentKey.self)] as? String == "value9")
    }

    @Test func testMergeCreatingCycle() {
        var env1 = UVEnvironmentValues()
        let env2 = UVEnvironmentValues()

        env1.merge(env2)

        // If we incorrectly merge env1 into env2, it could create a cycle
        // env2.merge(env1) // This would be problematic if allowed
    }
}
