# Ultraviolence FAQ

## Why isn't my Element rendering anything / Why does Metal debugger show "empty render encoder"?

### Problem
Your custom Element compiles successfully but no rendering occurs, and the Metal debugger shows "empty render encoder" with no draw commands being submitted.

### Cause
This typically happens when an Element's `body` property returns `any Element` instead of `some Element`:

```swift
// ❌ WRONG - This compiles but doesn't work
public var body: any Element {
    get throws {
        return RenderPipeline(...) { ... }
    }
}

// ✅ CORRECT - Use 'some Element'
public var body: some Element {
    get throws {
        return RenderPipeline(...) { ... }
    }
}
```

### Why This Happens
The framework needs concrete type information to properly traverse the element tree. Using `any Element` creates a type-erased existential that prevents the framework from walking into child elements and executing their lifecycle methods (like `workloadEnter`/`workloadExit`).

### Solution
Always use `some Element` as the return type for your Element's body property. This preserves the concrete type information needed for proper element tree traversal.

### Related Issues
- [#256](https://github.com/schwa/Ultraviolence/issues/256) - Framework should detect or warn when Element body returns 'any Element'