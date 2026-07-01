# Go Simplification

Behavior-preserving simplifications idiomatic to Go. Apply only what fits surrounding code. Favor clear, boring Go.

## Errors

- Return early on errors and keep the happy path unindented.
- Use `if err != nil { return ..., err }` unless wrapping adds useful context with `%w`.
- Remove error wrapping that adds no actionable context.
- Do not swallow errors with `_` unless the surrounding code documents why that is intentional.

## Control Flow

- Collapse `if x { return true } return false` into `return x`.
- Remove `else` after a branch that returns.
- Prefer `switch` over long `if`/`else if` ladders when it reads more clearly.
- Prefer `range` when the index is unused.

## Idioms

- Drop redundant type declarations when the type is obvious.
- Use composite literals directly instead of allocating and then assigning fields one by one.
- Use zero values instead of explicit zero initialization.
- Inline one-line helpers with one caller when the helper obscures intent.
- Do not introduce interfaces with one implementation just to abstract.

## Cleanup

- Delete comments that restate code.
- Remove unused imports, struct fields, params, and named returns that add nothing.
- Use compiler, `go test`, `go vet`, `staticcheck`, or `deadcode` where available before deleting non-local items.
- Let `gofmt` and `goimports` own formatting and import order.

## Avoid

- Do not add a dependency for what `strings`, `slices`, `maps`, `cmp`, or the standard library already covers.
- Do not introduce generics for small concrete duplication unless it clearly improves the code.
- Do not change exported function signatures, method sets, or interface contracts.
