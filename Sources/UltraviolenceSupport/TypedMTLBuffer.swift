import Metal

public struct TypedMTLBuffer<Element> {
    private var base: MTLBuffer
    public private(set) var count: Int
    public var capacity: Int {
        base.length / elementSize
    }

    private var elementSize: Int {
        MemoryLayout<Element>.stride
    }

    internal init(buffer: MTLBuffer, count: Int) {
        self.base = buffer
        self.count = count
    }
}

extension TypedMTLBuffer: Sequence {
    public func makeIterator() -> AnyIterator<Element> {
        let iterator = (0..<count).map { self[$0] }.makeIterator()
        return AnyIterator(iterator)
    }
}

extension TypedMTLBuffer: Collection {
    public var startIndex: Int {
        0
    }
    public var endIndex: Int {
        count
    }
    public func index(after i: Int) -> Int {
        i + 1
    }
    public subscript(position: Int) -> Element {
        get {
            let pointer = base.contents().bindMemory(to: Element.self, capacity: count)
            return pointer[position]
        }
        set {
            let pointer = base.contents().bindMemory(to: Element.self, capacity: count)
            pointer[position] = newValue
        }
    }
}

extension TypedMTLBuffer: MutableCollection {
}

extension TypedMTLBuffer: RandomAccessCollection {
}

// MARK: -

extension TypedMTLBuffer: Equatable where Element: Equatable {
    public static func == (lhs: TypedMTLBuffer, rhs: TypedMTLBuffer) -> Bool {
        guard lhs.count == rhs.count else {
            return false
        }
        return zip(lhs, rhs).allSatisfy(==)
    }
}

extension TypedMTLBuffer: Hashable where Element: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(count)
        for element in self {
            hasher.combine(element)
        }
    }
}

// MARK: -

public extension TypedMTLBuffer {
    var unsafeMTLBuffer: MTLBuffer {
        base
    }

    func withUnsafeMTLBuffer<R>(_ body: (MTLBuffer) throws -> R) rethrows -> R {
        try body(base)
    }
}
// MARK: -

public extension MTLDevice {
    func newTypedBuffer<Element>(capacity: Int, options: MTLResourceOptions) throws -> TypedMTLBuffer<Element> {
        let mtlBuffer = try makeBuffer(length: capacity * MemoryLayout<Element>.stride, options: options).orThrow(.undefined)
        return TypedMTLBuffer(buffer: mtlBuffer, count: 0)
    }
    func newTypedBuffer<Element>(values: [Element], options: MTLResourceOptions) throws -> TypedMTLBuffer<Element> {
        let mtlBuffer = try makeBuffer(collection: values, options: options)
        return TypedMTLBuffer(buffer: mtlBuffer, count: values.count)
    }
}
