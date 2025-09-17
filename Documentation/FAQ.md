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

## Why am I getting "missingEnvironment(\.reflection)" errors?

### Problem
You get a fatal error like `Fatal error: missingEnvironment("\\UVEnvironmentValues.reflection")` when trying to use `.parameter()` modifiers.

### Cause
This happens when `.parameter()` modifiers are applied outside of a RenderPipeline or ComputePipeline context:

```swift
// ❌ WRONG - Parameters applied outside the pipeline
return RenderPipeline(vertexShader: vertexShader, fragmentShader: fragmentShader) {
    content
}
.parameter("uniforms", value: uniforms)  // Error: No reflection context here!
```

### Why This Happens
The `.parameter()` modifier needs access to shader reflection data to know where to bind the parameters. This reflection data is only available within the RenderPipeline or ComputePipeline's content closure.

### Solution
Apply `.parameter()` modifiers to elements inside the pipeline's content closure:

```swift
// ✅ CORRECT - Parameters applied inside the pipeline
return RenderPipeline(vertexShader: vertexShader, fragmentShader: fragmentShader) {
    content
        .parameter("uniforms", value: uniforms)  // Reflection context available here
}
```

This ensures the parameters have access to the pipeline's reflection data for proper binding.

## Why am I getting "Ambiguous parameter" errors?

### Problem
You get a fatal error like `Fatal error: Ambiguous parameter, found parameter named uniforms in both vertex (index: #1) and fragment (index: #0) shaders.`

### Cause
This happens when a parameter with the same name exists in both vertex and fragment shaders, and you don't specify which function to bind it to:

```swift
// ❌ WRONG - Ambiguous, parameter exists in both shaders
.parameter("uniforms", value: myUniforms)
```

### Why This Happens
When shaders share parameter names across vertex and fragment functions, the framework can't determine which one you want to bind to. Metal shaders often use the same buffer indices and names in both vertex and fragment stages.

### Solution
Explicitly specify the function type when binding parameters that exist in multiple shader stages:

```swift
// ✅ CORRECT - Explicitly specify function type
.parameter("uniforms", functionType: .vertex, value: myUniforms)
.parameter("uniforms", functionType: .fragment, value: myUniforms)
```

You can bind the same or different values to each stage as needed. This removes the ambiguity and ensures your parameters are bound to the correct shader stage.