# Python

Respect the project's Python version and tooling. In this user's repos that is `uv`, `ruff` and `ty`. Let the formatter own style.

## Usually deletable

- a class with `__init__` and one method, where a function does the job
- an abstract base class or `Protocol` with one implementation
- a config object or dataclass that carries what is really a constant
- `**kwargs` passed through layers that never use them; parameters every caller leaves at the default
- properties that only return a private attribute nobody else sets
- hand-rolled versions of `itertools`, `collections`, `functools`, `pathlib`, `shutil` or `contextlib`
- `isinstance` guards on values whose type the codebase already enforces internally
- CLI flags and environment variables added in the current change that the task did not ask for
- debug `print` calls and logging that restates the code

A bare `except Exception: pass` looks deletable but removing it changes behavior. Report it instead.

## Prove it is dead

- `ruff check --select F401,F811,F841,ARG` for unused imports, redefinitions, variables and arguments
- `vulture` when installed; `ty check` to catch what a removal broke
- Search for use by name: `getattr`, entry points in `pyproject.toml`, decorator registries, Django, Click and pytest plugin discovery, and `__all__`.
- pytest fixtures are requested by parameter name and `conftest.py` is loaded by convention, so search for the fixture name before deleting it.

## Tests

- Delete mock echo: `mock.return_value = x` followed by `assert f() == x`, and `assert_called_once_with` where the outcome is already asserted.
- Delete tests of dataclass equality or repr, and of attribute assignment in `__init__`.
- Merge tests that differ by input with `pytest.mark.parametrize` and give each case an `id`.
- Prefer a real temporary directory or an in-memory fake over patching internals; a test that patches the function it is testing proves nothing.
- Counts: `pytest --collect-only -q | tail -1`. Coverage: `pytest --cov=<package> -q` when `pytest-cov` is available.

## Keep

- validation at boundaries: CLI arguments, HTTP input, files, environment
- context managers for resources, and explicit `is None` checks where falsy values are valid
- public function signatures, default arguments and keyword behavior
