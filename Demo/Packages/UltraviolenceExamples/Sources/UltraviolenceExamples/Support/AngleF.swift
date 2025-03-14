public struct AngleF: Equatable, Sendable {
    public var radians: Float

    public static func radians(_ radians: Float) -> Self {
        .init(radians: radians)
    }

    public init(radians: Float) {
        self.radians = radians
    }
}

public extension AngleF {
    static let zero: AngleF = .init(radians: 0)
}

public extension AngleF {
    var degrees: Float {
        get {
            radians * 180 / .pi
        }
        set {
            radians = newValue * .pi / 180
        }
    }

    static func degrees(_ degrees: Float) -> AngleF {
        .init(degrees: degrees)
    }

    init(degrees: Float) {
        self.radians = degrees * .pi / 180
    }
}

public extension AngleF {
    static func + (lhs: AngleF, rhs: AngleF) -> AngleF {
        .init(radians: lhs.radians + rhs.radians)
    }

    static func += (lhs: inout AngleF, rhs: AngleF) {
        lhs.radians += rhs.radians
    }

    static func - (lhs: AngleF, rhs: AngleF) -> AngleF {
        .init(radians: lhs.radians - rhs.radians)
    }

    static func -= (lhs: inout AngleF, rhs: AngleF) {
        lhs.radians -= rhs.radians
    }

    static func * (lhs: AngleF, rhs: AngleF) -> AngleF {
        .init(radians: lhs.radians * rhs.radians)
    }

    static func *= (lhs: inout AngleF, rhs: AngleF) {
        lhs.radians *= rhs.radians
    }

    static func / (lhs: AngleF, rhs: AngleF) -> AngleF {
        .init(radians: lhs.radians / rhs.radians)
    }

    static func /= (lhs: inout AngleF, rhs: AngleF) {
        lhs.radians /= rhs.radians
    }
}

public extension AngleF {
    static func + (lhs: AngleF, rhs: Float) -> AngleF {
        .init(radians: lhs.radians + rhs)
    }

    static func += (lhs: inout AngleF, rhs: Float) {
        lhs.radians += rhs
    }

    static func - (lhs: AngleF, rhs: Float) -> AngleF {
        .init(radians: lhs.radians - rhs)
    }

    static func -= (lhs: inout AngleF, rhs: Float) {
        lhs.radians -= rhs
    }

    static func * (lhs: AngleF, rhs: Float) -> AngleF {
        .init(radians: lhs.radians * rhs)
    }

    static func *= (lhs: inout AngleF, rhs: Float) {
        lhs.radians *= rhs
    }

    static func / (lhs: AngleF, rhs: Float) -> AngleF {
        .init(radians: lhs.radians / rhs)
    }

    static func /= (lhs: inout AngleF, rhs: Float) {
        lhs.radians /= rhs
    }
}
