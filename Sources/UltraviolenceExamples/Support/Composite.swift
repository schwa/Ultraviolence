public struct Composite <each T> {
    private let children: (repeat each T)

    public init(_ children: repeat each T) {
        self.children = (repeat each children)
    }
}

extension Composite: Equatable where repeat each T: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        for (left, right) in repeat (each lhs.children, each rhs.children) {
            guard left == right else {
                return false
            }
        }
        return true
    }
}

extension Composite: Hashable where repeat each T: Hashable {
    public func hash(into hasher: inout Hasher) {
        for child in repeat (each children) {
            child.hash(into: &hasher)
        }
    }
}

extension Composite: Sendable where repeat each T: Sendable {
}
