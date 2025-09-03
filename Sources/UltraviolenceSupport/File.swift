//
//  File.swift
//  Ultraviolence
//
//  Created by Jonathan Wight on 9/2/25.
//


public func clamp<T>(_ value: T, to range: ClosedRange<T>) -> T where T: Comparable {
    min(max(value, range.lowerBound), range.upperBound)
}

public extension FloatingPoint {
    func clamped(to range: ClosedRange<Self>) -> Self {
        clamp(self, to: range)
    }
}

public func wrap(_ value: Double, to range: ClosedRange<Double>) -> Double {
    let size = range.upperBound - range.lowerBound
    let normalized = value - range.lowerBound
    return (normalized.truncatingRemainder(dividingBy: size) + size).truncatingRemainder(dividingBy: size) + range.lowerBound
}

public extension FloatingPoint {
    func wrapped(to range: ClosedRange<Self>) -> Self {
        let rangeSize = range.upperBound - range.lowerBound
        let wrappedValue = (self - range.lowerBound).truncatingRemainder(dividingBy: rangeSize)
        return (wrappedValue < 0 ? wrappedValue + rangeSize : wrappedValue) + range.lowerBound
    }
}
