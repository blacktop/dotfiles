# CSS Simplification

Behavior-preserving simplifications for CSS and preprocessors. Apply only what fits surrounding code. Behavior means the rendered result; verify nothing shifts visually when practical.

## Shorthands

- Collapse longhands into shorthands only when all affected values are intentionally set.
- Use `0` instead of `0px`.
- Use shorter hex only when the existing style allows it.
- Combine selectors that share a declaration block when order and specificity do not change which rule wins.

## Modern Layout

- Use flexbox or grid instead of positioning or float workarounds only when the file already uses those patterns and the rendered layout is unchanged.
- Prefer `gap` for spacing between flex or grid children when it matches existing browser targets.
- Prefer logical properties when the codebase already uses them.
- Use custom properties to remove repeated literal values only when the repeated value has shared meaning.

## Cleanup

- Remove redundant or overridden declarations inside the same rule.
- Drop vendor prefixes only when the project tooling or browser targets make them unnecessary.
- Delete empty rule blocks and dead selectors orphaned by the current change after confirming markup or components no longer reference them.
- Keep SCSS nesting shallow; avoid adding new deep selector chains.

## Avoid

- Do not change specificity in a way that alters cascade behavior.
- Do not merge rules whose order matters.
- Do not remove load-bearing `!important` declarations without checking the cascade.
- Do not introduce a framework or utility library for local cleanup.
