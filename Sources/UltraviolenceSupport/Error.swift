public enum UltraviolenceError: Error {
    case missingEnvironment(String)
    case missingBinding(String)
    case resourceCreationFailure
    case deviceCababilityFailure(String)
}

public extension Optional {
    func orThrow(_ error: @autoclosure () -> UltraviolenceError) throws -> Wrapped {
        // swiftlint:disable:next self_binding
        guard let value = self else {
            throw error()
        }
        return value
    }
}
