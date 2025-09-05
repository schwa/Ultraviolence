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

internal extension Element {
    func visitChildren(_ visit: (any Element) throws -> Void) throws {
        if let bodyless = self as? any BodylessElement {
            try bodyless.visitChildrenBodyless(visit)
        } else if Body.self != Never.self {
            try visit(body)
        }
    }
}
