import Foundation
import simd
import UltraviolenceExamples

internal struct TeapotSimulation {
    var teapots: [Teapot] = []
    var boundingBox: BoundingBox = .init(min: [-4, 0, -4], max: [4, 4, 4])

    init(count: Int) {
        // create random teapots
        teapots = (0..<count).map { _ in
            Teapot(
                position: [Float.random(in: -1...1), Float.random(in: -1...1), Float.random(in: -1...1)],
                rotation: simd_quatf(angle: .init(Float.random(in: 0...(2 * .pi))), axis: [Float.random(in: -1...1), Float.random(in: -1...1), Float.random(in: -1...1)]),
                rotationVelocity: simd_quatf(angle: .init(Float.random(in: -1...1)), axis: [Float.random(in: -1...1), Float.random(in: -1...1), Float.random(in: -1...1)]),
                velocity: [Float.random(in: -1...1), Float.random(in: -1...1), Float.random(in: -1...1)] * 5,
                color: [Float.random(in: 0...1), Float.random(in: 0...1), Float.random(in: 0...1)]
            )
        }
    }

    mutating func step(duration: TimeInterval) {
        teapots = teapots.map { teapot in
            var teapot = teapot
            teapot.position += teapot.velocity * Float(duration)
            if teapot.position.x < boundingBox.min.x {
                teapot.position.x = boundingBox.min.x
                teapot.velocity.x = -teapot.velocity.x
            }
            if teapot.position.x > boundingBox.max.x {
                teapot.position.x = boundingBox.max.x
                teapot.velocity.x = -teapot.velocity.x
            }
            if teapot.position.y < boundingBox.min.y {
                teapot.position.y = boundingBox.min.y
                teapot.velocity.y = -teapot.velocity.y
            }
            if teapot.position.y > boundingBox.max.y {
                teapot.position.y = boundingBox.max.y
                teapot.velocity.y = -teapot.velocity.y
            }
            if teapot.position.z < boundingBox.min.z {
                teapot.position.z = boundingBox.min.z
                teapot.velocity.z = -teapot.velocity.z
            }
            if teapot.position.z > boundingBox.max.z {
                teapot.position.z = boundingBox.max.z
                teapot.velocity.z = -teapot.velocity.z
            }
            teapot.rotation = simd_slerp(teapot.rotation, teapot.rotation * teapot.rotationVelocity, Float(duration))
            return teapot
        }
    }
}

extension Teapot {
    var matrix: simd_float4x4 {
        var matrix = simd_float4x4.identity
        matrix *= simd_float4x4(translation: position) // Apply translation last
        matrix *= simd_float4x4(rotation)             // Apply rotation second
        matrix *= simd_float4x4(scale: [0.2, 0.2, 0.2]) // Apply scaling first
        return matrix
    }
}

internal struct Teapot {
    var position: SIMD3<Float>
    var rotation: simd_quatf
    var rotationVelocity: simd_quatf
    var velocity: SIMD3<Float>
    var color: SIMD3<Float>
}

extension BouncingTeapotsDemoView: DemoView {
}
