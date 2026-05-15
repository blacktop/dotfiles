# Visual Quality Checklist

Use this before building a nontrivial visual artifact and again before handoff. The parent skill's rules win: single file, no external resources, no CDN libraries, no build step.

## Pick the Shape

Choose one primary visual metaphor before writing HTML:

- **Timeline / Gantt-lite** — dates, phases, gates, long-running work.
- **Process / flowchart** — ordered steps, branches, handoffs, failure paths.
- **Architecture / system map** — components, ownership zones, protocols, trust boundaries.
- **Relationship map / ERD-style view** — entities, fields, keys, dependencies, cardinality.
- **Dashboard / status snapshot** — KPIs, validation matrix, exact counts, deltas.
- **Comparison matrix / table** — options x criteria, sortable or filterable when useful.
- **Kanban / queue** — work states, blockers, ownership, throughput.
- **Mind map / concept explainer** — hierarchy and lateral relationships.
- **Interactive editor** — user changes inputs and exports markdown or JSON.

If no shape clearly fits, stay in markdown or ask one focused question.

## Context Rules

- If the request says "our", "current", "this repo", names a file, or references an active plan, read the relevant local context first.
- Use exact values from the prompt, repo, plan, or command output. Do not invent metrics, dates, names, paths, owners, or statuses.
- Unknowns are allowed only when labeled as unknown, stale, assumed, or example data.
- Put the most important answer in the first viewport: what changed, what failed, what decision is needed, or what the map explains.

## Design Rules

- Make relationships explicit: arrows need labels, zones need headings, status colors need legends, and axes need units.
- Use one accent color plus semantic red/amber/green when status demands it.
- Avoid decorative icons, random blobs, generic purple/blue gradients, repeated shadow cards, and visual elements that do not carry information.
- Prefer SVG for diagrams and CSS/HTML for dashboards and tables. Canvas is fine only when SVG/HTML would be awkward and labels remain readable.
- Avoid force-layout diagrams unless interaction is essential; deterministic placement is easier to inspect and compare.
- Leave enough whitespace to scan, but keep operational views dense enough to compare rows without excessive scrolling.

## Accessibility And Responsive Checks

- Test the artifact mentally at 360px wide. Text must wrap, controls must remain reachable, and important tables need an intentional overflow strategy.
- Do not depend on hover. Hover can enhance; click, tap, keyboard, or always-visible controls must carry the workflow.
- Every interactive element is a real `button`, `a`, `input`, `select`, or element with an appropriate role and keyboard handling.
- Add `:focus-visible` styles for keyboard users.
- Add `aria-label` or visible text where icon-only controls would otherwise be ambiguous.
- Respect `prefers-reduced-motion` when using transitions, animation, or auto-scrolling.
- Keep color contrast readable and never encode status by color alone.

## Useful Fragments

Skip link for longer pages:

```html
<a class="skip-link" href="#main">Skip to content</a>
```

```css
.skip-link {
  position: absolute;
  left: -999px;
  top: 0.5rem;
  z-index: 10;
  padding: 0.5rem 0.75rem;
  background: Canvas;
  color: CanvasText;
  border: 1px solid #8886;
}
.skip-link:focus { left: 0.5rem; }
```

Baseline keyboard and reduced-motion CSS:

```css
:focus-visible {
  outline: 2px solid Highlight;
  outline-offset: 3px;
}

@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    scroll-behavior: auto !important;
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}
```

Responsive table wrapper:

```html
<div class="table-scroll" role="region" aria-label="Validation matrix" tabindex="0">
  <table><!-- rows --></table>
</div>
```

```css
.table-scroll { overflow-x: auto; }
.table-scroll:focus-visible { outline: 2px solid Highlight; outline-offset: 3px; }
```

## Pre-Handoff Checklist

- The first viewport answers the user's main question within about 10 seconds.
- The visual metaphor matches the task and there is not a second competing metaphor fighting it.
- Every number, date, path, label, and status comes from known context or is explicitly marked.
- The page opens directly from disk and needs no server, build, CDN, network, or package install.
- The external-resource scan from `SKILL.md` returns no executable/resource matches.
- The 360px layout is usable, with no clipped controls or unreadable labels.
- Keyboard focus is visible and all controls can be reached without a mouse.
- Color meanings are labeled and contrast is legible in the shipped theme.
- Motion is optional and reduced-motion users still get the same information.
- No overlapping nodes, duplicate IDs, unclosed tags, or smart quotes in HTML attributes.
