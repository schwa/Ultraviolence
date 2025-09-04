import UltraviolenceSupport

@MainActor
public protocol Element {
    associatedtype Body: Element
    @MainActor @ElementBuilder var body: Body { get throws }
}

extension Never: Element {
    public typealias Body = Never
}

public extension Element where Body == Never {
    var body: Never {
        unreachable("`body` is not implemented for `Never` types (on \(self)).")
    }
}

