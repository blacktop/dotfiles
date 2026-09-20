# Swift

Follow the project's Swift version, concurrency settings and lint config. Let the formatter own style.

## Usually deletable

- a protocol with one conforming type that exists only "for testability" when no test substitutes it
- pass-through layers: a manager, coordinator, factory or view model that forwards calls and holds no state or logic of its own
- a hand-written `init`, `Equatable`, `Hashable` or `Codable` conformance that the compiler synthesizes identically
- a generic wrapper or type-erased box used with one concrete type; `AnyView` where the concrete view type works
- `@Published`, `@State` or `@Observable` properties nothing reads
- a singleton that one call site uses and could own directly
- completion-handler wrappers around an API that is already `async`
- `DispatchQueue.main.async` inside code that is already `@MainActor`
- `#available` and `@available` checks below the deployment target
- an extension holding one function with one caller

## Prove it is dead

- `swift build` or `xcodebuild` warnings for unused values and variables that are never mutated
- `periphery scan` for unused declarations, when installed
- Many things are reached without a direct reference, so search before deleting: delegate and data-source methods called by a framework, `@objc` and `#selector`, `dynamic`, Interface Builder outlets and actions, `@main`, `#Preview`, `CodingKeys`, key paths, and `NSClassFromString`.
- In a Swift package, `public` and `open` declarations are API; leave them.

## Tests

- Delete tests that only check the subject was created (`XCTAssertNotNil(sut)`), tests of synthesized `Equatable` or a `Codable` round trip with no custom keys or decoding, and protocol-mock expectations where the outcome is already asserted.
- Merge tests that differ by input with Swift Testing's `@Test(arguments:)`, or a case array in XCTest, keeping a label per case.
- Keep `Codable` tests when there are custom `CodingKeys`, date or key strategies, or a hand-written decoder, because the wire format is a contract.
- Keep performance tests that CI runs, and snapshot tests of layouts someone deliberately approved.
- Counts: `swift test list | wc -l`. Coverage: `swift test --enable-code-coverage`, then `xcrun llvm-cov report` on the generated profile; in Xcode projects use `xcodebuild test -enableCodeCoverage YES`.

## Keep

- actor isolation, `@MainActor` and `Sendable` annotations; do not loosen them to delete code
- `[weak self]` wherever a retain cycle is possible, and `defer` cleanup
- `guard let` and decoding checks on data from the network, files or user defaults
- access control on package API
