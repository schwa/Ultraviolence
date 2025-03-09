import Metal
import MetalKit

public func isPOD<T>(_ type: T.Type) -> Bool {
    _isPOD(type)
}

public func isPOD<T>(_ value: T) -> Bool {
    _isPOD(T.self)
}

public func isPODArray<T>(_ value: [T]) -> Bool {
    _isPOD(T.self)
}

public func unreachable(_ message: @autoclosure () -> String = String(), file: StaticString = #file, line: UInt = #line) -> Never {
    fatalError(message(), file: file, line: line)
}
