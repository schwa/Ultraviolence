import Testing
import Metal
@testable import UltraviolenceExamples

@Suite("BufferView Tests")
struct BufferViewTests {
    let device = MTLCreateSystemDefaultDevice()!

    @Test("RawBufferView initialization")
    func testRawBufferViewInit() {
        let view = RawBufferView(stride: 16, offset: 8, count: 10)
        #expect(view.stride == 16)
        #expect(view.offset == 8)
        #expect(view.count == 10)
    }

    @Test("BufferView initialization with default stride")
    func testBufferViewDefaultStride() {
        let view = BufferView<Float>(count: 5)
        #expect(view.stride == MemoryLayout<Float>.stride)
        #expect(view.offset == 0)
        #expect(view.count == 5)
    }

    @Test("BufferView initialization with custom stride")
    func testBufferViewCustomStride() {
        let view = BufferView<Float>(stride: 8, offset: 4, count: 5)
        #expect(view.stride == 8)
        #expect(view.offset == 4)
        #expect(view.count == 5)
    }

    @Test("MTLBuffer subscript with BufferView single element")
    func testBufferViewSingleElementAccess() throws {
        let values: [Float] = [1.0, 2.0, 3.0, 4.0, 5.0]
        let buffer = device.makeBuffer(bytes: values, length: values.count * MemoryLayout<Float>.stride, options: [])!
        let view = BufferView<Float>(count: values.count)

        #expect(buffer[view, 0] == 1.0)
        #expect(buffer[view, 2] == 3.0)
        #expect(buffer[view, 4] == 5.0)

        buffer[view, 2] = 10.0
        #expect(buffer[view, 2] == 10.0)
    }

    @Test("MTLBuffer subscript with BufferView range as UnsafeBufferPointer")
    func testBufferViewRangeUnsafeBufferPointer() throws {
        let values: [Float] = [1.0, 2.0, 3.0, 4.0, 5.0]
        let buffer = device.makeBuffer(bytes: values, length: values.count * MemoryLayout<Float>.stride, options: [])!
        let view = BufferView<Float>(count: values.count)

        let range: UnsafeBufferPointer<Float> = buffer[view, 1..<4]
        #expect(range.count == 3)
        #expect(range[0] == 2.0)
        #expect(range[1] == 3.0)
        #expect(range[2] == 4.0)
    }

    @Test("MTLBuffer subscript with BufferView range as Array")
    func testBufferViewRangeArray() throws {
        let values: [Float] = [1.0, 2.0, 3.0, 4.0, 5.0]
        let buffer = device.makeBuffer(bytes: values, length: values.count * MemoryLayout<Float>.stride, options: [])!
        let view = BufferView<Float>(count: values.count)

        let array: [Float] = buffer[view, 1..<4]
        #expect(array == [2.0, 3.0, 4.0])

        buffer[view, 1..<4] = [10.0, 20.0, 30.0]
        let updatedArray: [Float] = buffer[view, 1..<4]
        #expect(updatedArray == [10.0, 20.0, 30.0])
    }

    @Test("MTLBuffer subscript with type parameter single element")
    func testBufferTypeSubscriptSingleElement() throws {
        let values: [Float] = [1.0, 2.0, 3.0, 4.0, 5.0]
        let buffer = device.makeBuffer(bytes: values, length: values.count * MemoryLayout<Float>.stride, options: [])!

        #expect(buffer[Float.self, 0] == 1.0)
        #expect(buffer[Float.self, 2] == 3.0)

        buffer[Float.self, 1] = 15.0
        #expect(buffer[Float.self, 1] == 15.0)
    }

    @Test("MTLBuffer subscript with type parameter range as UnsafeBufferPointer")
    func testBufferTypeSubscriptRangeUnsafeBufferPointer() throws {
        let values: [Int32] = [10, 20, 30, 40, 50]
        let buffer = device.makeBuffer(bytes: values, length: values.count * MemoryLayout<Int32>.stride, options: [])!

        let range: UnsafeBufferPointer<Int32> = buffer[Int32.self, 1..<3]
        #expect(range.count == 2)
        #expect(range[0] == 20)
        #expect(range[1] == 30)
    }

    @Test("MTLBuffer subscript with type parameter range as Array")
    func testBufferTypeSubscriptRangeArray() throws {
        let values: [Int32] = [10, 20, 30, 40, 50]
        let buffer = device.makeBuffer(bytes: values, length: values.count * MemoryLayout<Int32>.stride, options: [])!

        let array: [Int32] = buffer[Int32.self, 0..<3]
        #expect(array == [10, 20, 30])

        buffer[Int32.self, 2..<5] = [100, 200, 300]
        let updatedArray: [Int32] = buffer[Int32.self, 2..<5]
        #expect(updatedArray == [100, 200, 300])
    }

    @Test("BufferView with offset")
    func testBufferViewWithOffset() throws {
        let values: [Float] = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0]
        let buffer = device.makeBuffer(bytes: values, length: values.count * MemoryLayout<Float>.stride, options: [])!

        let view = BufferView<Float>(offset: 2 * MemoryLayout<Float>.stride, count: 4)

        #expect(buffer[view, 0] == 3.0)
        #expect(buffer[view, 1] == 4.0)

        let array: [Float] = buffer[view, 0..<3]
        #expect(array == [3.0, 4.0, 5.0])
    }

    @Test("RawBufferView subscript")
    func testRawBufferViewSubscript() throws {
        let values: [UInt8] = [1, 2, 3, 4, 5, 6, 7, 8]
        let buffer = device.makeBuffer(bytes: values, length: values.count, options: [])!

        let view = RawBufferView(stride: 1, offset: 2, count: 4)

        let rawPointer = buffer[view, 0..<3]
        #expect(rawPointer.count == 3)
        #expect(rawPointer[0] == 3)
        #expect(rawPointer[1] == 4)
        #expect(rawPointer[2] == 5)
    }

    @Test("MTLDevice makeBuffer with BufferView")
    func testMakeBufferWithView() throws {
        let values: [Float] = [1.0, 2.0, 3.0, 4.0]
        let view = BufferView<Float>(count: values.count)

        let buffer = try device.makeBuffer(view: view, values: values, options: [])

        #expect(buffer.length == values.count * MemoryLayout<Float>.stride)

        let retrievedValues: [Float] = buffer[view, 0..<values.count]
        #expect(retrievedValues == values)
    }

    @Test("BufferView equality")
    func testBufferViewEquality() {
        let view1 = BufferView<Float>(stride: 4, offset: 8, count: 10)
        let view2 = BufferView<Float>(stride: 4, offset: 8, count: 10)
        let view3 = BufferView<Float>(stride: 8, offset: 8, count: 10)

        #expect(view1 == view2)
        #expect(view1 != view3)
    }

    @Test("RawBufferView equality")
    func testRawBufferViewEquality() {
        let view1 = RawBufferView(stride: 16, offset: 8, count: 5)
        let view2 = RawBufferView(stride: 16, offset: 8, count: 5)
        let view3 = RawBufferView(stride: 16, offset: 4, count: 5)

        #expect(view1 == view2)
        #expect(view1 != view3)
    }
}