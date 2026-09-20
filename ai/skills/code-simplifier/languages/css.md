# CSS and Preprocessors

Behavior here is the rendered result. Let the formatter own style; do not rewrite values into equivalent shorter forms.

## Usually deletable

- selectors and rule blocks no markup, component or template references anymore
- declarations overridden later in the same rule, and duplicate rules
- empty rule blocks, and custom properties nothing reads
- vendor prefixes the project's browser targets or autoprefixer make unnecessary
- positioning or float workarounds that a flex or grid container already in place makes redundant

## Prove it is dead

- Search templates, components and scripts for the class, id or custom property, including names built from strings and utility-class config.
- Check the project's browser targets (`browserslist`) before dropping a prefix or fallback.
- Look at the affected page when practical; the cascade is not visible from the file.

## Keep

- specificity and source order wherever they decide which rule wins
- load-bearing `!important` declarations until you have checked the cascade
- Do not introduce a framework or utility library for a local cleanup.
