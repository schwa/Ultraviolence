import SwiftUI

// TODO: Move into modifier
public enum DraggableValueBehavior: Equatable {
    case linear
    case clamping(ClosedRange<Double>)
    case wrapping(ClosedRange<Double>)
}

// TODO: Move into modifier GestureKind
public enum DraggableValueAxis {
    case horizontal
    case vertical
}

public extension View {
    // TODO: 'InteractiveValue'?
    func draggableValue(_ value: Binding<Double>, axis: DraggableValueAxis, scale: Double, behavior: DraggableValueBehavior, gestureKind: DraggableValueViewModifier.GestureKind = .drag) -> some View {
        self.modifier(DraggableValueViewModifier(value: value, axis: axis, scale: scale, behavior: behavior, gestureKind: gestureKind))
    }
}

// TODO: #134 Make generic for any VectorArithmetic and add a transform closure for axis handling?
// TODO: "GestureBasedValueModifier"/"InteractiveValueModifier"?
public struct DraggableValueViewModifier: ViewModifier {

    public enum GestureKind {
        case drag
        case magnify
    }

    @Binding
    var value: Double

    @State
    private var animatedValue: Double

    var axis: DraggableValueAxis
    var scale: Double
    var behavior: DraggableValueBehavior
    var minimimDragDistance: Double
    var predictedThreshold: Double
    var animationMaxDelay: TimeInterval
    var gestureKind: GestureKind

    @State
    private var initialValue: Double?

    @State
    private var lastEventTime: TimeInterval?

    public init(value: Binding<Double>, axis: DraggableValueAxis, scale: Double, behavior: DraggableValueBehavior, minimimDragDistance: Double = 10, predictedThreshold: Double = 10, animationMaxDelay: TimeInterval = 0.2, gestureKind: GestureKind = .drag) {
        self._value = value
        self.animatedValue = value.wrappedValue
        self.axis = axis
        self.scale = scale
        self.behavior = behavior
        self.minimimDragDistance = minimimDragDistance
        self.predictedThreshold = predictedThreshold
        self.animationMaxDelay = animationMaxDelay
        self.gestureKind = gestureKind
    }

    public func body(content: Content) -> some View {
        content
            .simultaneousGesture(gestureKind == .drag ? dragGesture : nil)
            .simultaneousGesture(gestureKind == .magnify ? magnifyGesture : nil)
            .modifier(AnimatableValueCallbackModifier(initialValue: animatedValue) { newValue in
                value = newValue
            })
    }

    var dragGesture: some Gesture {
        DragGesture(minimumDistance: minimimDragDistance)
            .onChanged { gesture in
                if initialValue == nil {
                    initialValue = value
                }
                value = newValue(for: gesture.translation)
                lastEventTime = Date().timeIntervalSinceReferenceDate
            }
            .onEnded { gesture in
                // TODO: #135 DragGestures' predictions are mostly junk. Refactor to this to keep own prediction logic.
                defer {
                    initialValue = nil
                    lastEventTime = nil
                }
                let newValue = newValue(for: gesture.predictedEndTranslation)
                if let lastEventTime, Date.timeIntervalSinceReferenceDate - lastEventTime > animationMaxDelay {
                    return
                }
                guard abs(newValue - value) >= predictedThreshold else {
                    return
                }
                withAnimation(Animation.linear(duration: 0.3)) {
                    animatedValue = newValue
                }
            }
    }

    var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { gesture in
                if initialValue == nil {
                    initialValue = value
                }
                value = newValue(for: gesture.magnification)
                lastEventTime = Date().timeIntervalSinceReferenceDate
            }
            .onEnded { gesture in
                defer {
                    initialValue = nil
                    lastEventTime = nil
                }

                let newValue = newValue(for: gesture.magnification)
                if let lastEventTime, Date.timeIntervalSinceReferenceDate - lastEventTime > animationMaxDelay {
                    return
                }
                guard abs(newValue - value) >= predictedThreshold else {
                    return
                }
                withAnimation(Animation.linear(duration: 0.3)) {
                    animatedValue = newValue
                }
            }
    }

    func newValue(for input: CGFloat) -> Double {
        var newValue = (initialValue ?? value) + input * scale
        switch behavior {
        case .linear:
            // Nothing to do here.
            break
        case .clamping(let range):
            newValue = newValue.clamped(to: range)
        case .wrapping(let range):
            newValue = newValue.wrapped(to: range)
        }
        return newValue
    }

    func newValue(for translation: CGSize) -> Double {
        let input: Double
        switch axis {
        case .horizontal:
            input = translation.width
        case .vertical:
            input = translation.height
        }
        return newValue(for: input)
    }
}

// MARK: -

public struct AnimatableValueCallbackModifier <T>: ViewModifier, @preconcurrency Animatable where T: VectorArithmetic {
    public var animatableData: T
    var callback: (T) -> Void

    public init(initialValue: T, callback: @escaping (T) -> Void) {
        self.animatableData = initialValue
        self.callback = callback
    }

    public func body(content: Content) -> some View {
        content
            .onChange(of: animatableData) {
                callback(animatableData)
            }
    }
}
