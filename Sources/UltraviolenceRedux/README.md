# NotSwiftUI

[Objc.io](https://www.objc.io)'s series of Swift talks about SwiftUI internals provide an excellent glimpse into how SwiftUI works under the hood. This repository takes the example code they produced in that series (and released in this repo: https://github.com/objcio/S01E268-state-and-bindings) and modernises it for Swift 6. Portions of the code are copyright Objc.io and portions are copyright Jonathan Wight. The license is still the original MIT license.

## Modernisation

Here's what's changed from the original:

- ACL attributes have been added as needed to provide a clear API surface.
- A new `isEqual(Any,Any)` function that gets rid of the hack and the reliance on `_openExistential` SPI (https://github.com/swiftlang/swift-evolution/blob/main/proposals/0352-implicit-open-existentials.md))
- TupleView now uses Swift 5.9 parameter packs (https://github.com/swiftlang/swift-evolution/blob/main/proposals/0393-parameter-packs.md)) and Swift 6 parameter pack iteration (https://www.swift.org/blog/pack-iteration/). This means you're no longer limited to 2 elements in your view bodies.
- Handling of Optionals in the ViewBuilder
- The global state in View.buildViewTree() is made atomic via `OSAllocatedUnfairLock`
- Clean up of all `as!` and `!` operators. Fatal errors now all provide meaningful error messages.
- Some reorganisation and tidying up of code.
- Unit tests now use the new Testable frameowork. As such all tests now needed to be in a single serialized test suite so as to not stomp on each other's global states (Testing runs in parallel normally).
- Some attempt to make the framework concurrent friendly - with `@MainActor` being added as appropriate

## Possible Future Work

- [X] Add support for environment.
- [X] Eliminate the global state if at all possible.
- [X] `@Entry` macro.
- [ ] Replace Swift @propertyWrapper with Macros where sensible.
- [ ] Add in support for Observation (get rid of ObservedObject))

## Objc.io's SwiftUI State Explained Series

- [S01E261 - Views and Nodes (SwiftUI State Explained)](https://talk.objc.io/episodes/S01E261-views-and-nodes)
- [S01E262 - Observed Objects (SwiftUI State Explained)](https://talk.objc.io/episodes/S01E262-observed-objects)
- [S01E263 - Tuple Views and View Builders (SwiftUI State Explained)](https://talk.objc.io/episodes/S01E263-tuple-views-and-view-builders)
- [S01E264 - Comparing Views (SwiftUI State Explained)](https://talk.objc.io/episodes/S01E264-comparing-views)
- [S01E265 - Bindings (SwiftUI State Explained)](https://talk.objc.io/episodes/S01E265-bindings)
- [S01E266 - State Properties (SwiftUI State Explained)](https://talk.objc.io/episodes/S01E266-state-properties)
- [S01E267 - State Dependencies (SwiftUI State Explained)](https://talk.objc.io/episodes/S01E267-state-dependencies)
- [S01E268 - State and Bindings (SwiftUI State Explained)](https://talk.objc.io/episodes/S01E268-state-and-bindings)
