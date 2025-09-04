internal import Foundation

internal struct OnChange<Value: Equatable, Content>: Element where Content: Element {
    let value: Value
    let initial: Bool
    let action: (Value, Value) -> Void
    let content: Content
    
    @UVState
    private var previousValue: Value?
    
    @UVState
    private var hasInitialized: Bool
    
    init(value: Value, initial: Bool, action: @escaping (Value, Value) -> Void, content: Content) {
        self.value = value
        self.initial = initial
        self.action = action
        self.content = content
        self.hasInitialized = false
    }
    
    public var body: some Element {
        // Check if this is the initial setup
        if !hasInitialized {
            if initial {
                // Call action with same value for both old and new on initial setup
                action(value, value)
            }
            hasInitialized = true
            previousValue = value
        } else if let oldValue = previousValue, oldValue != value {
            // Value has changed, call the action
            action(oldValue, value)
            previousValue = value
        }
        
        return content
    }
}

public extension Element {
    func onChange<V: Equatable>(
        of value: V,
        initial: Bool = false,
        perform action: @escaping (V, V) -> Void
    ) -> some Element {
        OnChange(value: value, initial: initial, action: action, content: self)
    }
    
    func onChange<V: Equatable>(
        of value: V,
        perform action: @escaping () -> Void
    ) -> some Element {
        OnChange(value: value, initial: false, action: { _, _ in action() }, content: self)
    }
}