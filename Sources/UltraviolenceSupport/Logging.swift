import Foundation
import os

internal let logger: Logger? = {
    guard ProcessInfo.processInfo.loggingEnabled else {
        return nil
    }
    return .init(subsystem: "io.schwa.ultraviolence-support", category: "default")
}()

public func withIntervalSignpost<T>(_ signposter: OSSignposter?, name: StaticString, id: OSSignpostID? = nil, around task: () throws -> T) rethrows -> T {
    guard let signposter else {
        return try task()
    }
    return try signposter.withIntervalSignpost(name, id: id ?? .exclusive, around: task)
}

public extension Logger {
    var verbose: Logger? {
        ProcessInfo.processInfo.verboseLoggingEnabled ? self : nil
    }
}
