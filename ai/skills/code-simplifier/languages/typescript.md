# TypeScript Simplification

Behavior-preserving simplifications idiomatic to TypeScript. Apply only what fits surrounding code and the project's configured compiler options.

## Types

- Let inference work for locals. Keep annotations on exported/public APIs and function parameters when they document the contract.
- Do not introduce `any`. Replace existing `any` only when a precise type or `unknown` plus narrowing is obvious and behavior is unchanged.
- Avoid new `as` casts. Prefer narrowing, typed helpers, or the types already given by the codebase.
- Prefer literal unions over `enum` only for private implementation details. Do not rewrite public enums.
- Use `interface` vs `type` consistently with the file.
- Collapse redundant generics only when the simpler form preserves inference and public API behavior.

## Control Flow

- Use early returns or lookup objects to reduce repetitive branch assignments when it stays clearer.
- Use optional chaining and nullish coalescing when it preserves falsy values.
- Prefer array methods when there are no side effects and the chain stays readable.
- Prefer `for...of` over a dense `reduce`.
- Do not introduce nested ternaries.

## Idioms

- Use destructuring with defaults when it clarifies intent.
- Prefer spread/rest over `Object.assign` and `.apply` when behavior is unchanged.
- Use template literals over string concatenation when clearer.
- Remove redundant `async`/`await`; keep `return await` inside `try` blocks when it affects catch behavior or stack traces.
- Drop non-null assertions when a guard or optional chaining expresses the invariant more safely.

## Cleanup

- Use `tsc`, `oxlint`, `eslint`, `knip`, `ts-prune`, or project tools to confirm unused locals, params, exports, and files before deleting them.
- Remove debug logging left by current work.
- Keep import ordering under the project's formatter or linter.

## Avoid

- Do not add runtime dependencies for standard language or DOM features.
- Do not introduce classes, decorators, or dependency injection to replace plain functions.
- Do not widen or change exported types.
- Do not add browser polyfills unless the target environment requires them.
