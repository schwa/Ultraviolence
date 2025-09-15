internal extension System {
    @MainActor
    func withCurrentSystem<R>(_ closure: () throws -> R) rethrows -> R {
        let saved = System.current
        defer { System.current = saved }
        System.current = self
        return try closure()
    }
}
