extension System {
    var recursiveDescription: String {
        var output = ""
        var depth = 0
        
        for event in self.traversalEvents {
            switch event {
            case .enter(let node):
                let element = node.element
                let prefix = String(repeating: "  ", count: depth)
                print("\(prefix)\(type(of: element))", to: &output)
                depth += 1
            case .exit(_):
                depth -= 1
            }
        }
        return output
    }

    func dump() {
        print(recursiveDescription)
    }
}
