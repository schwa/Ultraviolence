import simd

public protocol SortableSplatProtocol: Equatable, Sendable {
    var floatPosition: SIMD3<Float> { get }
}
