public indirect enum UltraviolenceError: Error, Equatable {
    case undefined
    case generic(String)
    case missingEnvironment(String)
    case missingBinding(String)
    case resourceCreationFailure(String)
    case deviceCababilityFailure(String)
    case textureCreationFailure
    case unexpectedError(Self)
    case noCurrentGraph
}

public extension Optional {
    func orThrow(_ error: @autoclosure () -> UltraviolenceError) throws -> Wrapped {
        // swiftlint:disable:next self_binding
        guard let value = self else {
            throw error()
        }
        return value
    }

    func orFatalError(_ message: @autoclosure () -> String = String()) -> Wrapped {
        // swiftlint:disable:next self_binding
        guard let value = self else {
            fatalError(message())
        }
        return value
    }

    func orFatalError(_ error: @autoclosure () -> UltraviolenceError) -> Wrapped {
        // swiftlint:disable:next self_binding
        guard let value = self else {
            fatalError("\(error())")
        }
        return value
    }
}
