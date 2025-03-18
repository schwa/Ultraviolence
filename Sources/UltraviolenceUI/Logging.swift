internal import Foundation
internal import os

internal let logger: Logger? = {
    guard let logging = ProcessInfo.processInfo.environment["LOGGING"] else {
        return nil
    }
    return Logger(subsystem: "io.schwa.ultraviolence-ui", category: "default")
}()

internal let signposter: OSSignposter? = .init(subsystem: "io.schwa.ultraviolence-ui", category: OSLog.Category.pointsOfInterest)
