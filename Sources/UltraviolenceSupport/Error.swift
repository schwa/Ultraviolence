public indirect enum UltraviolenceError: Error, Equatable {
    case undefined
    case generic(String)
    case missingEnvironment(String)
    case missingBinding(String)
    case resourceCreationFailure(String)
    case deviceCababilityFailure(String)
    case textureCreationFailure
    // TODO: #92 This should be more "impossible" than "unexpected".
    case unexpectedError(Self)
    case noCurrentGraph
}

extension UltraviolenceError {
    static var resourceCreationFailure: Self {
        resourceCreationFailure("Resource creation failure.")
    }
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
