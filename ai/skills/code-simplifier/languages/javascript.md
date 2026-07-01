# JavaScript Simplification

Behavior-preserving simplifications idiomatic to modern JavaScript. Apply only what fits surrounding code and supported runtime targets.

## Control Flow

- Use early returns to reduce nesting.
- Use optional chaining and nullish coalescing instead of `&&` or `||` only when falsy values such as `0`, `""`, and `false` must be preserved.
- Prefer array methods when there are no side effects and the result stays readable.
- Prefer `for...of` over a dense `reduce`.
- Use statements instead of nested ternaries.

## Idioms

- Use `const` and `let`; do not introduce `var`.
- Use destructuring and defaults when they clarify the code.
- Prefer spread/rest over `Object.assign`, `.concat`, `.apply`, and `arguments` when behavior is unchanged.
- Use template literals over string concatenation when it improves readability.
- Use arrow functions for callbacks; keep `function` when `this`, hoisting, surrounding style, or named stack traces matter.
- Remove redundant `return await` outside `try`/`catch`.

## Cleanup

- Delete dead branches, unused variables, and debug logging left by the current work.
- Use eslint, type checks, `knip`, or equivalent project tools where available before deleting exports or files.
- Do not convert promise chains to `async`/`await` unless the file already uses that style and the result is clearer.

## Avoid

- Do not pull in lodash, underscore, ramda, or similar libraries for standard language features.
- Do not convert module systems as part of simplification.
- Do not change exported function signatures, argument shapes, or error behavior.
