//
//  BoundingBox.swift
//  Ultraviolence
//
//  Created by Jonathan Wight on 9/2/25.
//


public  struct BoundingBox {
    public var min: SIMD3<Float>
    public var max: SIMD3<Float>

    public init(min: SIMD3<Float>, max: SIMD3<Float>) {
        self.min = min
        self.max = max
    }
}

