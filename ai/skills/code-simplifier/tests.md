# Pruning Tests

Tests are code. They take time to run, break when the implementation is refactored, and have to be read by whoever debugs a failure. A test that cannot fail for a real bug costs all of that and returns only false confidence. A small suite where every failure means something is worth more than a large one people learn to ignore.

## What earns its place

Keep a test when you can finish this sentence with a bug a user would notice: "this test fails when ___", and no other test fails for that same bug. In practice that means:

- behavior the task or the public contract promises, checked through the public entry point
- edges and errors: empty, zero, boundary, malformed, missing, too large, failure of a dependency
- a regression test for a real past bug; a name, comment or link pointing at an issue is a strong signal
- the only test that reaches a branch or an error path
- property, fuzz and golden-file tests for parsers, serializers and codecs
- integration tests that cross a real boundary the unit tests fake

## Usual deletions

- **Duplicates.** Several tests that drive the same path with inputs from the same equivalence class. Keep one case per class.
- **Tests of what the language, compiler or framework guarantees.** Getters and setters, constructors that store their arguments, derived equality, cloning or debug output, type conversions the type checker already enforces, that a mocking library works.
- **Mock echo.** The test configures a fake to return a value and asserts it gets that value back, or asserts the fake was called with certain arguments when the outcome is already asserted. These pass no matter what the real code does with real collaborators.
- **Implementation detail.** A private helper tested directly when the public path already covers it; call order, internal state, exact log lines, or exact error text when the error kind is the contract. These fail on harmless refactors and pass on real bugs.
- **Cannot fail.** No assertions, asserts only that nothing crashed when not crashing is not the behavior under test, compares a value with itself, or computes the expected value with the same code it is testing.
- **Trivial or unstable snapshots.** A snapshot of output nobody decided on, which gets regenerated whenever it breaks.
- **Tests for code you just deleted**, and tests that have been skipped or commented out with no stated reason. If a skip has a reason, leave it and report it.

## Merge rather than delete

When tests differ only by input and expected output, fold them into one table-driven test (`t.Run` subtests in Go, a case array or the repo's existing parametrize crate in Rust, `pytest.mark.parametrize`, `it.each`, `@Test(arguments:)` in Swift). Give every case a name so a failure still says which one broke. This usually removes more lines than deleting tests does, and loses nothing.

## Show that a deletion is safe

Use the cheapest check that settles the question; do not run all of them for every test.

1. **Name the redundancy.** Write down which remaining test fails for the same bug. If you cannot name one, the test is not redundant.
2. **Compare coverage when it is cheap.** Measure coverage of the code under test before and after, using the command in the language guide. A drop in covered lines or branches of non-test code means you removed the only test reaching something: restore it, or keep a slimmer version. Unchanged coverage does not prove the assertions were equivalent, so it supports step 1 rather than replacing it.
3. **Spot-check by mutation when in doubt.** Break the line the test claims to guard, for example flip the condition or return early, and run the suite. If only that test fails, it is unique; keep it. If nothing fails, neither that test nor the rest guards the line, and that gap belongs in the report. Undo the mutation immediately and confirm with `git diff` that it is gone.

## Do not remove

- a failing test, or an assertion that is inconvenient; never weaken an assertion to make a suite pass
- regression tests tied to an issue, and the only test of an error or security path
- fuzz targets, property tests and golden files for parsers and serialization
- examples that double as documentation: Go `Example` functions, Rust doc tests, doctest blocks
- benchmarks the repo's tooling or CI runs

Do not add tests during this pass, apart from the single table that replaces several tests. After pruning, delete the fixtures, fakes, helpers and test data files that nothing uses anymore, and check for fixtures that are looked up by name rather than imported.
