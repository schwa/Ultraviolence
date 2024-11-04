enum UltraviolenceError: Error {
    case missingEnvironment
    case missingBinding
    case resourceCreationFailure
}

extension Optional {
    func orThrow(_ error: @autoclosure () -> UltraviolenceError) throws -> Wrapped {
        guard let value = self else {
            throw error()
        }
        return value
    }
}
