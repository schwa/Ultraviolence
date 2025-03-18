internal import Foundation
import os

internal let logger: Logger? = {
    guard let logging = ProcessInfo.processInfo.environment["LOGGING"] else {
        return nil
    }
    return Logger(subsystem: "io.schwa.ultraviolence-support", category: "default")
}()

internal let signposter: OSSignposter? = .init(subsystem: "io.schwa.ultraviolence-support", category: OSLog.Category.pointsOfInterest)

public extension Optional where Wrapped == OSSignposter {
//    func withIntervalSignpost<T>(_ name: StaticString, id: OSSignpostID? = .exclusive, _ message: SignpostMetadata, around task: () throws -> T) rethrows -> T {
//        switch (self, id) {
//        case (.some(let signposter), .some(let id)):
//            return try signposter.withIntervalSignpost(name, id: id, message, around: task)
//        default:
//            return try task()
//        }
//    }

    func withIntervalSignpost<T>(_ name: StaticString, id: OSSignpostID?, around task: () throws -> T) rethrows -> T {
        switch (self, id) {
        case (.some(let signposter), .some(let id)):
            return try signposter.withIntervalSignpost(name, id: id, around: task)
        default:
            return try task()
        }
    }
}
