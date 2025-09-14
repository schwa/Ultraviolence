// TODO: #226 This is dangerous - walking the tree can modify state (e.g., EnvironmentReader can break things)
// TODO: #226 We should only walk the "System tree" instead of the Element tree to avoid state mutations

public extension Element {
    @MainActor
    func dump(to output: inout String, indent: Int = 0) throws {
        let indentString = String(repeating: "  ", count: indent)

        output.append("\(indentString)\(debugName)\n")

        // Visit children and recursively dump them
        try visitChildren { child in
            try child.dump(to: &output, indent: indent + 1)
        }
    }

    @MainActor
    func dump() throws -> String {
        var output = ""
        try dump(to: &output)
        return output
    }

    @MainActor
    func printDump() throws {
        print(try dump())
    }
}

// More detailed dump with additional information
public extension Element {
    @MainActor
    func dumpVerbose(to output: inout String, indent: Int = 0) throws {
        let indentString = String(repeating: "  ", count: indent)
        let typeName = String(describing: type(of: self))

        // Get type identifier for structural identity
        let typeId = ObjectIdentifier(type(of: self) as any Element.Type).shortId

        // Check if it's a BodylessElement
        let isBodyless = self is any BodylessElement

        output.append("\(indentString)\(typeName)")
        output.append(" [id: \(typeId), bodyless: \(isBodyless)]")
        output.append("\n")

        // Visit children and recursively dump them
        try visitChildren { child in
            try child.dumpVerbose(to: &output, indent: indent + 1)
        }
    }

    @MainActor
    func dumpVerbose() throws -> String {
        var output = ""
        try dumpVerbose(to: &output)
        return output
    }
}
