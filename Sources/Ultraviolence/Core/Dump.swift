public struct DumpOptions: OptionSet, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let `default`: DumpOptions = [.dumpElement]
    public static let dumpElement = Self(rawValue: 1 << 0)
    public static let dumpNode = Self(rawValue: 1 << 0)
}

public extension Node {
    @MainActor
    func dump(options: DumpOptions = .default, to output: inout some TextOutputStream) throws {
        func dump(for node: Node) -> String {
            let elements: [String?] = [
                "id: \(ObjectIdentifier(node))",
                node.parent == nil ? "no parent" : nil,
                node.children.isEmpty ? "no children" : "\(node.children.count) children",
                node.needsRebuild ? "needs rebuild" : nil,
                node.element == nil ? "no element" : nil,
                node.previousElement == nil ? "no previous element" : nil,
                "state: \(node.stateProperties.keys.joined(separator: "|"))",
                "env: \(node.environmentValues.storage.values.keys.map { "\($0)" }.joined(separator: "|"))",
                node.debugLabel == nil ? nil : "debug: \(node.debugLabel!)"
            ]
            return elements.compactMap(\.self).joined(separator: ", ")
        }
        visit { depth, node in
            let indent = String(repeating: "  ", count: depth)
            if options.contains(.dumpElement) {
                let element = node.element
                if let element {
                    let typeName = String(describing: type(of: element)).split(separator: "<").first ?? ""
                    print("\(indent)\(typeName)", terminator: "", to: &output)
                    if options.contains(.dumpNode) {
                        print(" (\(dump(for: node)))", terminator: "", to: &output)
                    }
                    print("", to: &output)
                }
                else {
                    print("\(indent)<no element!>", to: &output)
                }
            }
        }
    }

    @MainActor
    func dump(options: DumpOptions = .default) throws {
        var s = ""
        try dump(options: options, to: &s)
        print(s, terminator: "")
    }
}

// MARK: -

public extension Graph {
    @MainActor
    func dump(options: DumpOptions = .default, to output: inout some TextOutputStream) throws {
        try rebuildIfNeeded()
        try root.dump(options: options, to: &output)
    }

    @MainActor
    func dump(options: DumpOptions = .default) throws {
        var s = ""
        try dump(options: options, to: &s)
        print(s, terminator: "")
    }
}

// MARK: -

public extension Element {
    func dump(options: DumpOptions = .default, to output: inout some TextOutputStream) throws {
        let graph = try Graph(content: self)
        try graph.rebuildIfNeeded()
        try graph.dump(options: options, to: &output)
    }

    func dump(options: DumpOptions = .default) throws {
        var output = String()
        try dump(options: options, to: &output)
        print(output)
    }
}
