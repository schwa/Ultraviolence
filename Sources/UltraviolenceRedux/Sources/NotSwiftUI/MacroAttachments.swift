@attached(accessor)
@attached(peer, names: prefixed(__Key_))
public macro Entry() = #externalMacro(module: "NotSwiftUIMacros", type: "EntryMacro")
