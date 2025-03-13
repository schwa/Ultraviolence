import SwiftUI

public enum DraggableValueBehavior {
    case clamping
    case wrapping
}

public enum DraggableValueAxis {
    case horizontal
    case vertical
}

public extension View {
    func draggableValue(_ value: Binding<Double>, axis: DraggableValueAxis, range: ClosedRange<Double>? = nil, scale: Double, behavior: DraggableValueBehavior) -> some View {
        self.modifier(DraggableValueViewModifier(value: value, axis: axis, range: range, scale: scale, behavior: behavior))
    }
}

public struct DraggableValueViewModifier: ViewModifier {
    @Binding
    var value: Double
    var axis: DraggableValueAxis
    var range: ClosedRange<Double>?
    var scale: Double
    var behavior: DraggableValueBehavior
    var minimimDragDistance: Double
    var predictedThreshold: Double

    @State
    var initialValue: Double?

    public init(value: Binding<Double>, axis: DraggableValueAxis, range: ClosedRange<Double>? = nil, scale: Double, behavior: DraggableValueBehavior, minimimDragDistance: Double = 10, predictedThreshold: Double = 10) {
        self._value = value
        self.axis = axis
        self.range = range
        self.scale = scale
        self.behavior = behavior
        self.minimimDragDistance = minimimDragDistance
        self.predictedThreshold = predictedThreshold
    }

    public func body(content: Content) -> some View {
        content.simultaneousGesture(dragGesture)
    }

    var dragGesture: some Gesture {
        DragGesture(minimumDistance: minimimDragDistance)
            .onChanged { gesture in
                if initialValue == nil {
                    initialValue = value
                }
                value = newValue(for: gesture.translation)
            }
            .onEnded { gesture in
                let newValue = newValue(for: gesture.predictedEndTranslation)
                guard abs(newValue - value) > predictedThreshold else {
                    return
                }
                withAnimation(Animation.linear(duration: 0.3)) {
                    print("Animating from \(value) to \(newValue).")
                    value = newValue
                }
            }
    }

    func newValue(for translation: CGSize) -> Double {
        let input: Double
        switch axis {
        case .horizontal:
            input = translation.width
        case .vertical:
            input = translation.height
        }
        var newValue = (initialValue ?? value) + input * scale
        if let range {
            switch behavior {
            case .clamping:
                newValue = newValue.clamped(to: range)
            case .wrapping:
                newValue = newValue.wrapped(to: range)
            }
        }
        return newValue
    }
}
