internal import Foundation
internal import os
import UltraviolenceSupport

internal let logger: Logger? = {
    guard ProcessInfo.processInfo.loggingEnabled else {
        return nil
    }
    return .init(subsystem: "io.schwa.ultraviolence", category: "default")
}()

internal let signposter: OSSignposter? = {
    guard ProcessInfo.processInfo.loggingEnabled else {
        return nil
    }
    return .init(subsystem: "io.schwa.ultraviolence", category: OSLog.Category.pointsOfInterest)
}()
