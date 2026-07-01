# Python Simplification

Behavior-preserving simplifications idiomatic to Python. Apply only what fits surrounding code and the project's configured Python version.

## Control Flow

- Use early returns and guard clauses to reduce nesting.
- Prefer truthiness checks for collections and explicit `is None` for `None`.
- Use comprehensions when they remain readable and have no side effects.
- Prefer `any()` and `all()` over loops that only flip a boolean flag.
- Use `match` or lookup dictionaries only when they are clearer than the existing branch structure and supported by the project's Python version.

## Idioms

- Use unpacking and `enumerate`/`zip` instead of manual indexing when clearer.
- Use `with` for resource management.
- Prefer f-strings over `%` and `.format()` when the file already uses modern style.
- Use `pathlib.Path` only when the file already leans that way or the conversion stays local and clear.
- Do not add type hints to untyped code as part of simplification unless asked.

## Cleanup

- Remove unused imports, variables, and debug `print`s.
- Use `ruff`, `ty`, tests, or project tools to confirm unused code before deleting non-local items.
- Collapse no-ops and redundant `else` after `return`.
- Delete comments that restate code; keep comments that explain why.

## Avoid

- Do not add dependencies such as `more-itertools` or `toolz` for standard-library behavior.
- Do not change public function signatures, default arguments, or kwargs behavior.
- Respect the project's formatter and import tool. In this user's repos, prefer `uv`, `ruff`, and `ty` when Python tooling exists.
