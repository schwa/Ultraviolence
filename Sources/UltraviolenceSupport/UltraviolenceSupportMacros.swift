@freestanding(expression)
public macro uuidString() -> (String) = #externalMacro(module: "UltraviolenceMacros", type: "UUIDMacro")

@attached(member, names: named(Meta))
public macro MetaEnum() = #externalMacro(module: "UltraviolenceMacros", type: "MetaEnumMacro")

@attached(accessor)
@attached(peer, names: prefixed(__Key_))
public macro UVEntry() = #externalMacro(module: "UltraviolenceMacros", type: "UVEntryMacro")
