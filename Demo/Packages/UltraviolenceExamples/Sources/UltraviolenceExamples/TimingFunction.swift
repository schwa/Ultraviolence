import SwiftUI

public protocol TimingFunction {
    func solve(_ x: Float) -> Float
}

public extension TimingFunction {
    func value(time: TimeInterval, period: TimeInterval, offset: Float, in range: ClosedRange<Float>) -> Float {
        let t = Float(fmod(time, period) / period) + offset
        return range.lowerBound + solve(t) * (range.upperBound - range.lowerBound)
    }
    func value(time: TimeInterval, period: TimeInterval, in range: ClosedRange<Float>) -> Float {
        value(time: time, period: period, offset: 0, in: range)
    }
}

// https://easings.net/#

public struct LinearTimingFunction: TimingFunction {
    public init() {
    }

    public func solve(_ x: Float) -> Float {
        x
    }
}

public struct SinusoidalTimingFunction: TimingFunction {
    public init() {
    }

    public func solve(_ x: Float) -> Float {
        0.5 * (1 + sin(.pi * x - .pi / 2))
    }
}

public struct EaseInOutTimingFunction: TimingFunction {
    public init() {
    }

    public func solve(_ x: Float) -> Float {
        let r = CubicBezier(p1x: 0.65, p1y: 0, p2x: 0.35, p2y: 1).solve(for: Double(x)) ?? 0
        return Float(r)
    }
}

public struct EaseInOutTimingFunction2: TimingFunction {
    public init() {
    }

    public func solve(_ x: Float) -> Float {
        x < 0.5 ? 4 * x * x * x : 1 - pow(-2 * x + 2, 3) / 2
    }
}

public struct ReversedTimingFunction<T>: TimingFunction where T: TimingFunction {
    let other: T

    public init(_ other: T) {
        self.other = other
    }

    public func solve(_ x: Float) -> Float {
        other.solve(1 - x)
    }
}

public struct ForwardAndReverseTimingFunction<T>: TimingFunction where T: TimingFunction {
    let other: T

    public init(_ other: T) {
        self.other = other
    }

    public func solve(_ x: Float) -> Float {
        if x < 0.5 {
            return other.solve(2 * x)
        }
        return other.solve(2 - 2 * x)
    }
}

// https://pomax.github.io/bezierinfo/#yforx
internal struct CubicBezier {
    let p1x: Double
    let p1y: Double
    let p2x: Double
    let p2y: Double

    // Solve for y given x using Cardano's formula
    internal func solve(for x: Double) -> Double? {
        let p0x = 0.0, p0y = 0.0
        let p3x = 1.0, p3y = 1.0

        // Convert Bézier equation into standard cubic form: at^3 + bt^2 + ct + d = x
        let a = -p0x + 3 * p1x - 3 * p2x + p3x
        let b = 3 * p0x - 6 * p1x + 3 * p2x
        let c = -3 * p0x + 3 * p1x
        let d = p0x - x

        // Solve for t using Cardano's method
        guard let t = solveCubic(a: a, b: b, c: c, d: d) else { return nil }

        // Evaluate Bézier y at the found t
        return cubicBezier(t: t, p0: p0y, p1: p1y, p2: p2y, p3: p3y)
    }

    // Solves the cubic equation at^3 + bt^2 + ct + d = 0 using Cardano's formula
    private func solveCubic(a: Double, b: Double, c: Double, d: Double) -> Double? {
        if abs(a) < 1e-8 { return solveQuadratic(b: b, c: c, d: d) }

        let A = b / a
        let B = c / a
        let C = d / a

        let p = B - A * A / 3
        let q = C - A * B / 3 + 2 * A * A * A / 27
        let discriminant = q * q / 4 + p * p * p / 27

        if discriminant > 0 {
            let sqrtD = sqrt(discriminant)
            let u = cbrt(-q / 2 + sqrtD)
            let v = cbrt(-q / 2 - sqrtD)
            let t = u + v - A / 3
            return (t >= 0 && t <= 1) ? t : nil
        }
        if discriminant == 0 {
            let u = cbrt(-q / 2)
            let t1 = 2 * u - A / 3
            let t2 = -u - A / 3
            return (t1 >= 0 && t1 <= 1) ? t1 : (t2 >= 0 && t2 <= 1) ? t2 : nil
        }
        let phi = acos(-q / (2 * sqrt(-p * p * p / 27)))
        let t1 = 2 * sqrt(-p / 3) * cos(phi / 3) - A / 3
        let t2 = 2 * sqrt(-p / 3) * cos((phi + 2 * .pi) / 3) - A / 3
        let t3 = 2 * sqrt(-p / 3) * cos((phi + 4 * .pi) / 3) - A / 3
        return [t1, t2, t3].first { $0 >= 0 && $0 <= 1 }
    }

    // Fallback: Solve quadratic equation bt^2 + ct + d = 0
    private func solveQuadratic(b: Double, c: Double, d: Double) -> Double? {
        if abs(b) < 1e-8 { return (abs(c) < 1e-8) ? nil : -d / c }

        let discriminant = c * c - 4 * b * d
        if discriminant < 0 { return nil }

        let sqrtD = sqrt(discriminant)
        let t1 = (-c + sqrtD) / (2 * b)
        let t2 = (-c - sqrtD) / (2 * b)
        return (t1 >= 0 && t1 <= 1) ? t1 : (t2 >= 0 && t2 <= 1) ? t2 : nil
    }

    // Evaluate a cubic Bézier function at t
    private func cubicBezier(t: Double, p0: Double, p1: Double, p2: Double, p3: Double) -> Double {
        let u = 1.0 - t
        return u * u * u * p0 + 3 * u * u * t * p1 + 3 * u * t * t * p2 + t * t * t * p3
    }
}

#Preview {
    let functions: [any TimingFunction] = [
        LinearTimingFunction(),
        SinusoidalTimingFunction(),
        EaseInOutTimingFunction(),
        EaseInOutTimingFunction2(),
        ReversedTimingFunction(LinearTimingFunction()),
        ForwardAndReverseTimingFunction(EaseInOutTimingFunction())
    ]

    ForEach(Array(functions.enumerated()), id: \.0) { _, function in
        Canvas { context, size in
            for x in stride(from: 0, through: 1, by: 0.01) {
                let y = Double(function.value(time: x, period: 1, in: 0 ... 1))
                context.draw(Text("•").foregroundStyle(Color.red), at: CGPoint(x: x * size.width, y: (1 - y) * size.height))
            }
        }
        .aspectRatio(4.0, contentMode: .fit)
        .background(Color.white)
    }
}
