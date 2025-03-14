public struct LoggingElement: Element, BodylessElement {
    public init() {
        // This line intentionally left blank.
    }

    func _expandNode(_ node: Node, context: ExpansionContext) throws {
        // This line intentionally left blank.
    }

    func setupEnter(_ node: Node) throws {
        logger?.log("setupEnter")
    }

    func setupExit(_ node: Node) throws {
        logger?.log("setupExit")
    }

    func workloadEnter(_ node: Node) throws {
        logger?.log("workloadEnter")
    }

    func workloadExit(_ node: Node) throws {
        logger?.log("workloadExit")
    }
}
