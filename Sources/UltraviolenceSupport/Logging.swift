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

public extension Optional where Wrapped == OSSignposter {
    func withIntervalSignpost<T>(_ name: StaticString, id: OSSignpostID?, around task: () throws -> T) rethrows -> T {
        switch (self, id) {
        case (.some(let signposter), .some(let id)):
            return try signposter.withIntervalSignpost(name, id: id, around: task)
        default:
            return try task()
        }
    }
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
