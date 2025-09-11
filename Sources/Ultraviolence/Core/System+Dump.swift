extension System {
    var recursiveDescription: String {
        var output = ""
        for identifier in self.orderedIdentifiers {
            guard let node = self.nodes[identifier] else {
                fatalError("TODO")
            }
            let element = node.element
            let depth = identifier.atoms.count - 1
            let prefix = String(repeating: "  ", count: depth)
            print("\(prefix)\(type(of: element))", to: &output)
        }
        return output
    }

    func dump() {
        print(recursiveDescription)
    }
}
