import Metal
import UltraviolenceSupport

struct RawBufferView: Equatable, Sendable {
    var stride: Int
    var offset: Int
    var count: Int

    init(stride: Int, offset: Int = 0, count: Int) {
        self.stride = stride
        self.offset = offset
        self.count = count
    }
}

struct BufferView<T>: Equatable, Sendable {
    var stride: Int
    var offset: Int
    var count: Int

    init(stride: Int? = nil, offset: Int = 0, count: Int) {
        self.stride = stride ?? MemoryLayout<T>.stride
        self.offset = offset
        self.count = count
    }
}

// MARK: -

extension MTLDevice {
    func makeBuffer<T>(view: BufferView<T>, values: [T], options: MTLResourceOptions) throws -> MTLBuffer {
        let length = view.stride * values.count
        guard let buffer = self.makeBuffer(length: length, options: options) else {
            throw UltraviolenceError.resourceCreationFailure("Failed to create MTLBuffer of length \(length)")
        }
        buffer[view, 0..<values.count] = values
        return buffer
    }
}

// MARK: -

extension MTLBuffer {
    subscript(view: RawBufferView, range: Range<Int>) -> UnsafeRawBufferPointer {
        get {
            let pointer = contents().advanced(by: view.offset + range.lowerBound * view.stride)
            return UnsafeRawBufferPointer(start: pointer, count: range.count)
        }
        set {
            precondition(newValue.count == range.count, "New value count must match range count")
            let pointer = contents().advanced(by: view.offset + range.lowerBound * view.stride)
            pointer.copyMemory(from: newValue.baseAddress!, byteCount: newValue.count * view.stride)
        }
    }

    subscript<T>(view: BufferView<T>, index: Int) -> T {
        get {
            let pointer = contents().advanced(by: view.offset + index * view.stride)
            return pointer.assumingMemoryBound(to: T.self).pointee
        }
        set {
            let pointer = contents().advanced(by: view.offset + index * view.stride)
            pointer.assumingMemoryBound(to: T.self).pointee = newValue
        }
    }

    subscript<T>(view: BufferView<T>, range: Range<Int>) -> UnsafeBufferPointer<T> {
        get {
            let pointer = contents().advanced(by: view.offset + range.lowerBound * view.stride)
            return UnsafeBufferPointer(start: pointer.assumingMemoryBound(to: T.self), count: range.count)
        }
        set {
            precondition(newValue.count == range.count, "New value count must match range count")
            let pointer = contents().advanced(by: view.offset + range.lowerBound * view.stride)
            pointer.assumingMemoryBound(to: T.self).update(from: newValue.baseAddress!, count: newValue.count)
        }
    }

    subscript<T>(view: BufferView<T>, range: Range<Int>) -> [T] {
        get { Array(self[view, range] as UnsafeBufferPointer<T>) }
        set {
            precondition(newValue.count == range.count, "New value count must match range count")
            newValue.withUnsafeBufferPointer { buffer in
                self[view, range] = buffer
            }
        }
    }
}

extension MTLBuffer {
    subscript<T>(type: T.Type, index: Int) -> T {
        get {
            let view = BufferView<T>(count: length / MemoryLayout<T>.stride)
            let pointer = contents().advanced(by: view.offset + index * view.stride)
            return pointer.assumingMemoryBound(to: T.self).pointee
        }
        set {
            let view = BufferView<T>(count: length / MemoryLayout<T>.stride)
            let pointer = contents().advanced(by: view.offset + index * view.stride)
            pointer.assumingMemoryBound(to: T.self).pointee = newValue
        }
    }

    subscript<T>(type: T.Type, range: Range<Int>) -> UnsafeBufferPointer<T> {
        get {
            let view = BufferView<T>(count: length / MemoryLayout<T>.stride)
            let pointer = contents().advanced(by: view.offset + range.lowerBound * view.stride)
            return UnsafeBufferPointer(start: pointer.assumingMemoryBound(to: T.self), count: range.count)
        }
        set {
            let view = BufferView<T>(count: length / MemoryLayout<T>.stride)
            precondition(newValue.count == range.count, "New value count must match range count")
            let pointer = contents().advanced(by: view.offset + range.lowerBound * view.stride)
            pointer.assumingMemoryBound(to: T.self).update(from: newValue.baseAddress!, count: newValue.count)
        }
    }

    subscript<T>(type: T.Type, range: Range<Int>) -> [T] {
        get {
            Array(self[type, range] as UnsafeBufferPointer<T>)
        }
        set {
            precondition(newValue.count == range.count, "New value count must match range count")
            newValue.withUnsafeBufferPointer { buffer in
                self[type, range] = buffer
            }
        }
    }
}
