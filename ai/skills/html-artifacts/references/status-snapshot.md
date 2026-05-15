# Status Snapshot Template

For long-running work where the user wants a single page that captures *what happened, what's true now, and what to decide next*. Markdown can carry the prose; HTML lets the reader scan and pivot.

Use this when the work has:

- A timeline worth showing as steps.
- Exact counts that must not be paraphrased ("8/12 tests passing", not "most tests pass").
- A validation matrix (axis × axis truth table).
- Decisions made and decisions still open.

## Sections to include

1. **Header** — project / topic, generated date, one-sentence summary.
2. **Timeline** — chronological steps with anchored IDs so you can link from elsewhere.
3. **Counts table** — every metric with the exact number, the target, and the delta. No prose substitutes.
4. **Validation matrix** — rows × columns × pass/fail or value cells.
5. **Decisions made** — what was settled, by whom, and the rationale link.
6. **Open decisions** — what's still live, the options, the recommended default.
7. **Next steps** — short list, each owning a verb.
8. **Voice blurb** — the ≤100-word spoken summary used if voice was requested.

## Skeleton

```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>{TOPIC} — Status Snapshot</title>
  <style>
    :root { color-scheme: light dark; }
    body { font: 16px/1.5 system-ui, sans-serif; margin: 2rem auto; max-width: 60rem; padding: 0 1rem; }
    h1, h2 { line-height: 1.2; }
    table { border-collapse: collapse; width: 100%; margin: 1rem 0; }
    th, td { padding: 0.4rem 0.6rem; border-bottom: 1px solid #8884; text-align: left; }
    .ok { color: #2a8f2a; } .bad { color: #c0392b; } .warn { color: #b8860b; }
    nav { position: sticky; top: 0; padding: 0.5rem 0; background: Canvas; border-bottom: 1px solid #8884; }
    nav a { margin-right: 1rem; }
    section { scroll-margin-top: 3rem; }
    .skip-link { position: absolute; left: -999px; top: 0.5rem; z-index: 10; padding: 0.5rem 0.75rem; background: Canvas; color: CanvasText; border: 1px solid #8886; }
    .skip-link:focus { left: 0.5rem; }
    .table-scroll { overflow-x: auto; }
    :focus-visible { outline: 2px solid Highlight; outline-offset: 3px; }
    @media (max-width: 640px) {
      body { margin: 1rem auto; }
      nav a { display: inline-block; margin: 0.2rem 0.8rem 0.2rem 0; }
      th, td { padding: 0.35rem 0.45rem; }
    }
    @media (prefers-reduced-motion: reduce) {
      *, *::before, *::after {
        scroll-behavior: auto !important;
        animation-duration: 0.01ms !important;
        animation-iteration-count: 1 !important;
        transition-duration: 0.01ms !important;
      }
    }
  </style>
</head>
<body>
  <a class="skip-link" href="#timeline">Skip to content</a>
  <header>
    <h1>{TOPIC}</h1>
    <p><strong>Generated:</strong> {YYYY-MM-DD} &middot; <strong>Summary:</strong> {ONE_SENTENCE}</p>
  </header>

  <nav>
    <a href="#timeline">Timeline</a>
    <a href="#counts">Counts</a>
    <a href="#matrix">Validation</a>
    <a href="#decisions">Decisions</a>
    <a href="#next">Next</a>
  </nav>

  <section id="timeline">
    <h2>Timeline</h2>
    <ol>
      <li id="t1"><strong>{DATE}</strong> — {EVENT}</li>
      <!-- repeat -->
    </ol>
  </section>

  <section id="counts">
    <h2>Counts</h2>
    <div class="table-scroll" role="region" aria-label="Counts table" tabindex="0">
      <table>
        <thead><tr><th>Metric</th><th>Actual</th><th>Target</th><th>Delta</th></tr></thead>
        <tbody>
          <tr><td>{METRIC}</td><td>{N}</td><td>{TARGET}</td><td class="ok|warn|bad">{±N}</td></tr>
        </tbody>
      </table>
    </div>
  </section>

  <section id="matrix">
    <h2>Validation Matrix</h2>
    <div class="table-scroll" role="region" aria-label="Validation matrix" tabindex="0">
      <table>
        <thead><tr><th></th><th>{COL_1}</th><th>{COL_2}</th></tr></thead>
        <tbody>
          <tr><th>{ROW_1}</th><td class="ok">pass</td><td class="bad">fail</td></tr>
        </tbody>
      </table>
    </div>
  </section>

  <section id="decisions">
    <h2>Decisions made</h2>
    <ul><li><strong>{DECISION}</strong> — {RATIONALE}</li></ul>

    <h2>Open decisions</h2>
    <ul>
      <li>
        <strong>{QUESTION}</strong>
        <ul><li>Options: {A}, {B}</li><li>Recommended: {DEFAULT}</li></ul>
      </li>
    </ul>
  </section>

  <section id="next">
    <h2>Next steps</h2>
    <ol><li>{ACTION_VERB} {OBJECT}</li></ol>
  </section>
</body>
</html>
```

## Voice blurb

If voice was requested, invoke the `speak` skill with:

> Status snapshot for {TOPIC} written. {N_PASS} of {N_TOTAL} validation cells passing. {N_OPEN} decisions still open. Next: {TOP_ACTION}.

Keep it ≤100 words and clean prose (no markdown, no URLs). The `speak` skill routes through `mcp-tts` with cloud fallback.

## Rules of thumb

- Never paraphrase a number. If the user wants to see "8 of 12", show "8 of 12" — not "most" or "the majority".
- Link every decision to its rationale (commit, plan file, or section anchor on the same page).
- If a count is stale, mark it stale in the cell — don't quietly carry it forward.
- One accent color. Reserve red for `.bad`, amber for `.warn`, green for `.ok`.
- Make the first viewport answer the user's main question quickly: current truth, open decision, or next action.
- Check the skeleton at 360px wide. Wide tables should scroll intentionally inside `.table-scroll`, not clip the page.
- Use the skip link and visible focus styles on long snapshots so keyboard navigation stays practical.
