internal func isEqual<LHS: Equatable, RHS: Equatable>(_ lhs: LHS, _ rhs: RHS) -> Bool {
    if let lhs = lhs as? RHS, lhs == rhs {
        return true
    }
    return false
}

internal func isEqual(_ lhs: Any, _ rhs: Any) -> Bool {
    guard let lhs = lhs as? any Equatable else {
        return false
    }
    guard let rhs = rhs as? any Equatable else {
        return false
    }
    return isEqual(lhs, rhs)
}
