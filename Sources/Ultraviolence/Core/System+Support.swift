internal extension System {
    @MainActor
    func withCurrentSystem<R>(_ closure: () throws -> R) rethrows -> R {
        let saved = System.current
        defer { System.current = saved }
        System.current = self
        return try closure()
    }

    func identifier(at indices: [Int]) -> StructuralIdentifier? {
        guard !indices.isEmpty else { return nil }
        // TODO: #223 This identifier lookup logic seems overly complex - consider refactoring for clarity
        // Build the structural identifier path from indices
        var currentPath: [StructuralIdentifier.Atom] = []
        // Walk through orderedIdentifiers to match the indices
        for (targetDepth, targetIndex) in indices.enumerated() {
            var foundAtCurrentDepth = false
            var currentIndexAtDepth = -1

            // For identifiers at the right depth...
            for identifier in orderedIdentifiers where identifier.atoms.count == targetDepth + 1 {
                    // Check if it matches our built path so far
                    if currentPath.enumerated().allSatisfy({ $0.element == identifier.atoms[$0.offset] }) {
                        currentIndexAtDepth += 1
                        if currentIndexAtDepth == targetIndex {
                            // Found the right element at this depth
                            currentPath.append(identifier.atoms[targetDepth])
                            foundAtCurrentDepth = true
                            break
                        }
                    }
            }

            if !foundAtCurrentDepth {
                return nil
            }
        }
        // Build the final identifier
        return StructuralIdentifier(atoms: currentPath)
    }

    func element(at indices: [Int]) -> (any Element)? {
        guard let targetIdentifier = identifier(at: indices) else {
            return nil
        }
        return nodes[targetIdentifier]?.element
    }

    func element<E>(at indices: [Int], type: E.Type) -> E? where E: Element {
        element(at: indices) as? E
    }
}
