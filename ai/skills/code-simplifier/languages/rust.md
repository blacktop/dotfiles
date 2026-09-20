# Rust

Follow the repo's lints and `AGENTS.md` first. Let `cargo fmt` own formatting; do not make style edits.

## Usually deletable

- a trait with one implementor and no `dyn` or generic consumer that needs it
- a builder for a struct with a few fields, where a struct literal or `Default` does the job
- a generic parameter or lifetime with a single instantiation; an elidable lifetime
- a hand-written impl that `#[derive]` produces
- `Arc<Mutex<_>>` around data with one owner on one thread
- `.clone()` that exists only to satisfy the borrow checker where a borrow works
- error enum variants that are never constructed, and `From` impls nothing uses
- a macro written for two call sites; a module holding one re-exported item
- Cargo features nobody enables
- `pub` that can be private or `pub(crate)` in a binary crate
- `#[allow(dead_code)]` or `#[allow(unused)]` together with the code it hides: delete both
- a `match` or `if let` that only forwards an error, where `?` says the same thing

## Prove it is dead

- `cargo check --all-targets --all-features`; the `dead_code` and `unused_*` warnings are reliable for private and `pub(crate)` items
- `cargo clippy --all-targets --all-features -- -D warnings`
- `cargo machete` or `cargo udeps` for unused dependencies, when installed
- In a library crate every `pub` item is public API; leave it. Check `#[cfg]`-gated code under the feature and target combinations the repo builds.
- Search for use through macros, `#[no_mangle]`, `extern "C"`, `build.rs` and serde field names.

## Tests

- Delete tests that assert derived behavior (`Debug`, `Clone`, `PartialEq`), that a constructor stored its arguments, or that only call `.unwrap()` and assert nothing.
- Merge tests that differ by input into one test looping over a named case array. Use `rstest` or a similar crate only if the repo already depends on it.
- Give `#[should_panic]` an `expected` string or replace it with an assertion on the returned error.
- Keep doc tests (they are documentation), `proptest` and fuzz targets, `trybuild` tests, and snapshot tests of parser or codegen output.
- Counts: `cargo test -- --list | grep -c ': test'`. Coverage: `cargo llvm-cov --summary-only` when `cargo-llvm-cov` is installed; otherwise rely on naming the redundant test.

## Keep

- **Recover-and-report semantics.** If code continues with a default or fallback value while collecting diagnostics, warnings, partial failures or multiple errors, do not collapse it into `?`, `.ok()?`, `unwrap_or_default` or a plain `Result`, unless the caller no longer needs both the successful value and the reported failure. Error accumulators, diagnostic vectors, `MultiError`-style parameters, and `(value, Option<E>)` or `(value, Vec<E>)` returns are meaningful when a function is designed to keep working after an error.
- error context (`.context(...)`, `map_err` that adds the operation), checked arithmetic, bounds checks and explicit limits on external input
- `unsafe` invariant checks and their `// SAFETY:` comments; `Drop` impls
- newtypes that distinguish values of the same primitive type
- This user's preferences: `crate::` paths over `super::`, explicit destructuring over `matches!`, no wildcard match arms, and no new `unwrap`, `expect` or `panic!` outside tests.
- Do not replace explicit control flow with combinators when that makes borrow errors, lifetimes or diagnostics harder to follow.
