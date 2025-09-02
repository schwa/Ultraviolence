internal import os

private let onceKeys = OSAllocatedUnfairLock(initialState: Set<String>())

public func once(key: String, _ body: () -> Void) {
    let run = onceKeys.withLockUnchecked { keys in
        guard keys.contains(key) == false else {
            return false
        }
        keys.insert(key)
        return true
    }
    if run {
        body()
    }
}
