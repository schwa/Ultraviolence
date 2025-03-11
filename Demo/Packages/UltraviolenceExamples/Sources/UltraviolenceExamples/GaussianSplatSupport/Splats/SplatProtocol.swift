import simd

// TODO: Rename to "SortableSplatProtocol" perhaps.
public protocol SplatProtocol: Equatable, Sendable {
    var floatPosition: SIMD3<Float> { get }
}
