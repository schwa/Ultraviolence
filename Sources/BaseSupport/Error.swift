public extension Optional {
    func orThrow(_ error: @autoclosure () -> Error) throws -> Wrapped {
        // swiftlint:disable:next self_binding
        guard let value = self else {
            throw error()
        }
        return value
    }
}
