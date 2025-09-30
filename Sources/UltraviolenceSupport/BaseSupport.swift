import Metal
import MetalKit

public func isPOD<T>(_ type: T.Type) -> Bool {
    _isPOD(type)
}

public func isPOD<T>(_: T) -> Bool {
    _isPOD(T.self)
}

public func isPODArray<T>(_: [T]) -> Bool {
    _isPOD(T.self)
}

public func unreachable(_ message: @autoclosure () -> String = String(), file: StaticString = #file, line: UInt = #line) -> Never {
    fatalError(message(), file: file, line: line)
}

public extension NSObject {
    func copyWithType<T>(_ type: T.Type) -> T where T: NSObject {
        (copy() as? T).orFatalError("Failed to copy \(type)")
    }
}
