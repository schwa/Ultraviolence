public struct Angle: Equatable, Sendable {
    public var radians: Float

    static func radians(_ radians: Float) -> Self {
        .init(radians: radians)
    }

    public init(radians: Float) {
        self.radians = radians
    }
}

public extension Angle {
    static let zero: Angle = .init(radians: 0)
}

public extension Angle {
    var degrees: Float {
        get {
            radians * 180 / .pi
        }
        set {
            radians = newValue * .pi / 180
        }
    }

    static func degrees(_ degrees: Float) -> Angle {
        .init(degrees: degrees)
    }

    init(degrees: Float) {
        self.radians = degrees * .pi / 180
    }
}

public extension Angle {
    static func + (lhs: Angle, rhs: Angle) -> Angle {
        .init(radians: lhs.radians + rhs.radians)
    }

    static func += (lhs: inout Angle, rhs: Angle) {
        lhs.radians += rhs.radians
    }

    static func - (lhs: Angle, rhs: Angle) -> Angle {
        .init(radians: lhs.radians - rhs.radians)
    }

    static func -= (lhs: inout Angle, rhs: Angle) {
        lhs.radians -= rhs.radians
    }

    static func * (lhs: Angle, rhs: Angle) -> Angle {
        .init(radians: lhs.radians * rhs.radians)
    }

    static func *= (lhs: inout Angle, rhs: Angle) {
        lhs.radians *= rhs.radians
    }

    static func / (lhs: Angle, rhs: Angle) -> Angle {
        .init(radians: lhs.radians / rhs.radians)
    }

    static func /= (lhs: inout Angle, rhs: Angle) {
        lhs.radians /= rhs.radians
    }
}
