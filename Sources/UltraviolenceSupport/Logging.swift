import Foundation
import os

internal let logger: Logger? = {
    guard ProcessInfo.processInfo.loggingEnabled else {
        return nil
    }
    return .init(subsystem: "io.schwa.ultraviolence-support", category: "default")
}()

internal let signposter: OSSignposter? = {
    guard ProcessInfo.processInfo.loggingEnabled else {
        return nil
    }
    return .init(subsystem: "io.schwa.ultraviolence-support", category: OSLog.Category.pointsOfInterest)
}()

public func withIntervalSignpost<T>(_ signposter: OSSignposter?, name: StaticString, id: OSSignpostID? = nil, around task: () throws -> T) rethrows -> T {
    guard let signposter else {
        return try task()
    }
    return try signposter.withIntervalSignpost(name, id: id ?? .exclusive, around: task)
}

public extension ProcessInfo {
    var loggingEnabled: Bool {
        return true
//        guard let value = environment["LOGGING"]?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else {
//            return false
//        }
//        return ["yes", "true", "y", "1", "on"].contains(value)
    }
}
