internal import Foundation
internal import os

internal let logger: Logger? = {
    guard let logging = ProcessInfo.processInfo.environment["LOGGING"] else {
        return nil
    }
    return Logger(subsystem: "UltraviolenceSupport", category: "UltraviolenceSupport")
}()
