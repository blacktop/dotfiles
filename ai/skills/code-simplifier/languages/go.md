# Go

Favor clear, boring Go. Let `gofmt` and `goimports` own formatting; do not make style edits.

## Usually deletable

- an interface with one implementation, declared next to that implementation rather than by its consumer
- functional options or a config struct for one or two knobs that every caller leaves at the default
- helpers that duplicate `slices`, `maps`, `strings`, `cmp`, `errors.Join`, or the `min`, `max` and `clear` builtins
- a wrapper function with one caller, and a package that holds one small function
- a wrapping layer (`fmt.Errorf("...: %w", err)`) that adds neither the operation nor an identifier; remove the layer, but do not reword messages that stay
- a goroutine and channel around work that is really sequential; a mutex around data only one goroutine touches
- a type parameter instantiated with one type; an unused `context.Context` or named result
- nil checks on values constructed a few lines above
- `else` after a branch that returns

## Prove it is dead

- `go build ./... && go vet ./...`
- `staticcheck ./...` (U1000) and `deadcode ./...` from `golang.org/x/tools/cmd/deadcode`, when installed
- `go mod tidy` and check the `go.mod` diff for dependencies that fell away
- Exported identifiers in a `main` package or under `internal/` are not public API. Exported identifiers in an importable package are, so leave them.
- Search for use through reflection, struct tags, `text/template`, `go:generate`, `go:linkname` and registration in `init`.

## Tests

- Merge tests that differ by input into one table with `t.Run(tc.name, ...)`.
- Delete tests of getters, constructors that only assign fields, and mock expectations (`AssertCalled`, `EXPECT().Times`) where the result is already asserted.
- Delete a no-op `TestMain` and helpers nothing calls.
- Keep `Example*` functions (compiled documentation), `Fuzz*` targets, golden files under `testdata/`, and benchmarks the repo runs.
- Counts: `go test -list '.*' ./pkg/... | grep -c '^Test'`. Coverage: `go test -cover ./pkg/...`, or `-coverprofile=c.out` with `go tool cover -func=c.out` for per-function numbers.

## Keep

- `defer` cleanup, context cancellation and deadlines
- error wrapping that adds the operation or the identifier, and sentinel or typed errors callers match with `errors.Is` or `errors.As`
- bounds and size checks on anything read from a file, the network or a user
