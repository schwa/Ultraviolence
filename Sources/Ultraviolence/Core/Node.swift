class Node: Identifiable {
    weak var system: System?
    var id: StructuralIdentifier
    var parentIdentifier: StructuralIdentifier?
    var element: (any Element)

    var stateProperties: [String: Any] = [:]
    var environmentValues = UVEnvironmentValues()
    var needsSetup = true

    init(system: System, id: StructuralIdentifier, parentIdentifier: StructuralIdentifier? = nil, element: (any Element)) {
        self.system = system
        self.id = id
        self.parentIdentifier = parentIdentifier
        self.element = element
    }
}
