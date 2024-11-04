public enum UltraviolenceError: Error {
    case missingEnvironment
    case missingBinding
    case resourceCreationFailure
}

internal extension Optional {
    func orThrow(_ error: @autoclosure () -> UltraviolenceError) throws -> Wrapped {
        // swiftlint:disable:next self_binding
        guard let value = self else {
            throw error()
        }
        return value
    }
}
