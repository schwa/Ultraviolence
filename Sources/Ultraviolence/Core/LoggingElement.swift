public struct LoggingElement: Element, BodylessElement {
    public init() {
        // This line intentionally left blank.
    }

    func system_setupEnter(_ node: NeoNode) throws {
        logger?.log("setupEnter")
    }

    func system_setupExit(_ node: NeoNode) throws {
        logger?.log("setupExit")
    }

    func system_workloadEnter(_ node: NeoNode) throws {
        logger?.log("workloadEnter")
    }

    func system_workloadExit(_ node: NeoNode) throws {
        logger?.log("workloadExit")
    }
}
