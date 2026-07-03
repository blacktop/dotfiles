# Rust Simplification

Behavior-preserving simplifications idiomatic to Rust. Apply only what fits surrounding code, `AGENTS.md`, and the user's Rust preferences.

## Error and Option Handling

- Use `?` instead of `match` or `if let` that only forwards an error.
- Prefer explicit error handling over `unwrap`, `expect`, or `panic`; do not introduce panics outside tests.
- Use `ok_or`, `ok_or_else`, `map`, `and_then`, `unwrap_or`, and `unwrap_or_else` when they improve readability without hiding control flow.
- Use `if let` or `let else` when one branch is trivial and it flattens the code.
- Preserve recover-and-report semantics. If code continues with a default/fallback value while collecting diagnostics, warnings, partial failures, or multiple errors, do not simplify it into `?`, `.ok()?`, `unwrap_or_default`, or a plain `Result` unless the caller no longer needs the successful value and the reported failure.
- Treat error accumulators, diagnostic vectors, `MultiError`-style parameters, and `(value, Option<E>)` / `(value, Vec<E>)` returns as meaningful when the function is designed to keep working after an error. Simplify the local shape only when both the value path and error-reporting path remain observable.

## Iterators and Control Flow

- Prefer iterator chains over manual `for` plus `push` when there are no side effects and the chain stays readable.
- Prefer `for` loops when side effects, mutation, or error handling make the loop clearer.
- Use `let else` and early returns to reduce nesting.
- Prefer pattern matching and destructuring over repeated field access.
- Avoid the `matches!` macro when repo instructions prefer explicit destructuring.

## Idioms

- Borrow instead of cloning when a borrow works cleanly.
- Prefer `&str` over `String` and `&[T]` over `&Vec<T>` in function arguments when this does not change public API or surrounding style.
- Use `impl Trait` in argument position instead of an unused generic parameter when it keeps the API clear.
- Derive obvious traits instead of hand-written implementations.
- Use struct update syntax and `Default` only when it improves clarity.
- Prefer `crate::` paths over `super::` in this user's Rust repos.

## Cleanup

- Remove needless `return`, redundant semicolons before returns, and casts the compiler can infer.
- Drop elidable lifetimes.
- Delete `#[allow(...)]` attributes that no longer suppress anything.
- Use `cargo fmt`, `cargo clippy`, and focused tests to validate behavior-preserving cleanup.
- Delete dead code only when compiler or search evidence shows it is not public API or otherwise reachable.

## Avoid

- Do not add a crate for standard-library behavior.
- Do not introduce traits or generics with one implementor just to abstract.
- Do not change `pub` API signatures or trait bounds during simplification.
- Do not replace explicit control flow with combinators when it makes borrow errors, lifetimes, or diagnostics harder to understand.
