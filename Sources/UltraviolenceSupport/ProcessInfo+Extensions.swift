import Foundation

public extension ProcessInfo {
    var loggingEnabled: Bool {
        environment["LOGGING"]?.isTruthy ?? false
    }

    var verboseLoggingEnabled: Bool {
        environment["VERBOSE"]?.isTruthy ?? false
    }

    var fatalErrorOnThrow: Bool {
        environment["FATALERROR_ON_THROW"]?.isTruthy ?? false
    }
}

private extension String {
    var isTruthy: Bool {
        ["yes", "true", "y", "1", "on"].contains(self.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
    }
}
