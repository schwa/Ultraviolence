internal import Foundation
internal import os.log
import UltraviolenceSupport

internal let logger: Logger? = {
    guard ProcessInfo.processInfo.loggingEnabled else {
        return nil
    }
    return .init(subsystem: "io.schwa.ultraviolence-ui", category: "default")
}()

internal let signposter: OSSignposter? = {
    guard ProcessInfo.processInfo.loggingEnabled else {
        return nil
    }
    return .init(subsystem: "io.schwa.ultraviolence-ui", category: OSLog.Category.pointsOfInterest)
}()
