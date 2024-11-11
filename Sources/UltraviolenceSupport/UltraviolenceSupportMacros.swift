/// A macro that produces both a value and a string containing the
/// source code that generated the value. For example,
///
///     #stringify(x + y)
///
/// produces a tuple `(x + y, "x + y")`.
@freestanding(expression)
public macro stringify<T>(_ value: T) -> (T, String) = #externalMacro(module: "UltraviolenceMacros", type: "StringifyMacro")

@freestanding(expression)
public macro uuidString() -> (String) = #externalMacro(module: "UltraviolenceMacros", type: "UUIDMacro")

@attached(member, names: named(Meta))
public macro MetaEnum() = #externalMacro(module: "UltraviolenceMacros", type: "MetaEnumMacro")

@attached(accessor)
@attached(peer, names: prefixed(__Key_))
public macro Entry() = #externalMacro(module: "UltraviolenceMacros", type: "EntryMacro")
