# JavaScript and TypeScript

Respect the project's runtime targets, module system and compiler options. Let the formatter and linter own style and import order.

## Usually deletable

- a class, decorator or dependency-injection container where plain functions do the job
- a wrapper hook, component or service with one user
- barrel files and re-exports nothing imports through
- runtime validation that duplicates the types at an internal boundary; keep it where data enters from outside
- type annotations the compiler infers for locals, and type aliases used once
- `try`/`catch` that only rethrows; `async` wrappers that only `return await` outside a `try`
- lodash, underscore or ramda calls that a native array, object or string method replaces, and polyfills the target environments no longer need
- enums, constant maps and feature flags with one value in use
- debug logging left by the current work

## Prove it is dead

- `tsc --noEmit`, and `oxlint` or `eslint` for unused locals, parameters and imports
- `knip` for unused exports, files and dependencies, when installed
- Search for dynamic use: string keys, `import()`, route and plugin registration, framework file conventions (pages, routes, config files), and `package.json` `exports`, `bin` and `scripts`.
- In a published package, anything exported from an entry point is public API; leave it.

## Tests

- Delete snapshots of trivial markup, tests that only check a component renders, and `toHaveBeenCalledWith` expectations where the outcome is already asserted.
- Delete tests of behavior the type checker enforces.
- Merge tests that differ by input with `it.each` or `test.each`, with a name per case.
- Counts and coverage: `vitest run --coverage` or the project's equivalent; `vitest list` for counts.

## Keep

- nullish semantics: do not swap `||` and `??`, or `&&` and `?.`, where `0`, `""` or `false` are valid values
- `return await` inside `try` blocks, because it changes what the `catch` sees
- exported types, function signatures, argument shapes and error behavior
- Do not introduce `any` or a new `as` cast to make a deletion compile.
