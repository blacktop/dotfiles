# Interactive Editor Template

Throwaway tools — sliders, drag-drop, live filters, picker grids — where the user manipulates inputs and exports a decision. The HTML is the workspace; the markdown export is the artifact that lives on.

Path: `docs/.ai/tools/<slug>.html`. Stays ignored. Once the user exports, the HTML can be discarded.

## When to reach for this

- The user is choosing between many options and wants to filter/sort them.
- Trade-off exploration where the inputs are continuous (sliders) and the output should update live.
- Layout / order tinkering: rank N items by dragging them into priority.
- Quick color/spacing/typography pickers where the preview is the point.

If the user just needs to *see* a comparison, use a status snapshot instead — no interactivity needed.

## Pattern 1 — Drag-to-rank with export

Vanilla HTML5 drag-and-drop. No libraries.

```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <title>Rank items</title>
  <style>
    :root { color-scheme: light dark; }
    body { font: 16px/1.4 system-ui; max-width: 40rem; margin: 2rem auto; padding: 0 1rem; }
    ol { list-style: none; padding: 0; }
    li { padding: 0.6rem 0.8rem; margin: 0.3rem 0; border: 1px solid #8886; border-radius: 6px; cursor: grab; user-select: none; }
    li.dragging { opacity: 0.4; }
    button { padding: 0.5rem 1rem; }
    textarea { width: 100%; min-height: 8rem; font: inherit; }
    :focus-visible { outline: 2px solid Highlight; outline-offset: 3px; }
  </style>
</head>
<body>
  <h1>Drag to rank</h1>
  <ol id="list">
    <li draggable="true">Option A</li>
    <li draggable="true">Option B</li>
    <li draggable="true">Option C</li>
  </ol>
  <button id="export">Export as markdown</button>
  <h2>Result</h2>
  <textarea id="out" readonly></textarea>

  <script>
    const list = document.getElementById('list');
    let dragging = null;

    list.addEventListener('dragstart', (e) => {
      dragging = e.target;
      e.target.classList.add('dragging');
    });
    list.addEventListener('dragend', (e) => {
      e.target.classList.remove('dragging');
      dragging = null;
    });
    list.addEventListener('dragover', (e) => {
      e.preventDefault();
      if (!dragging) return;
      const siblings = [...list.children].filter((li) => li !== dragging);
      const after = siblings.find((li) => {
        const r = li.getBoundingClientRect();
        return e.clientY < r.top + r.height / 2;
      });
      if (after) list.insertBefore(dragging, after);
      else list.appendChild(dragging);
    });

    document.getElementById('export').addEventListener('click', () => {
      const lines = [...list.children].map((li, i) => `${i + 1}. ${li.textContent.trim()}`);
      document.getElementById('out').value = lines.join('\n');
    });
  </script>
</body>
</html>
```

## Pattern 2 — Sliders that update a live preview

```html
<label>Padding <input id="pad" type="range" min="0" max="32" value="8" /></label>
<label>Radius  <input id="rad" type="range" min="0" max="24" value="4" /></label>
<div id="preview" aria-label="Preview"
     style="background: Canvas; color: CanvasText; border: 1px solid #8886;">Preview</div>
<button id="copy">Copy CSS</button>

<script>
  const pad = document.getElementById('pad');
  const rad = document.getElementById('rad');
  const preview = document.getElementById('preview');
  const sync = () => {
    preview.style.padding = pad.value + 'px';
    preview.style.borderRadius = rad.value + 'px';
  };
  [pad, rad].forEach((el) => el.addEventListener('input', sync));
  sync();

  document.getElementById('copy').addEventListener('click', async () => {
    const css = `padding: ${pad.value}px;\nborder-radius: ${rad.value}px;`;
    await navigator.clipboard.writeText(css);
  });
</script>
```

## Pattern 3 — Filterable grid

Type-to-filter without any framework. Use `[hidden]` for cheap show/hide.

```html
<label>Filter <input id="q" placeholder="Filter…" /></label>
<ul id="grid">
  <li data-tags="a b">Alpha</li>
  <li data-tags="a c">Bravo</li>
  <li data-tags="b c">Charlie</li>
</ul>

<script>
  const q = document.getElementById('q');
  const items = [...document.querySelectorAll('#grid li')];
  q.addEventListener('input', () => {
    const needle = q.value.trim().toLowerCase();
    for (const li of items) {
      const hay = (li.textContent + ' ' + (li.dataset.tags ?? '')).toLowerCase();
      li.hidden = needle && !hay.includes(needle);
    }
  });
</script>
```

## Export hook

Always provide one button that turns the current state into markdown (or JSON) so the decision survives the throwaway HTML. The receiving agent or human pastes it into the durable plan / task list.

Suggested export shapes:

- **Ranking** → numbered markdown list.
- **Slider config** → fenced code block with the chosen values.
- **Filter selection** → checklist with the surviving items pre-checked.

After export, tell the user: *"Copy the textarea into your plan / issue; the HTML in `docs/.ai/tools/` can be discarded."*

## Constraints (same as the parent skill)

- Single file, no external resources, no `fetch`, no dynamic imports.
- Vanilla JS unless the project already standardizes on something.
- Keyboard reachable for non-drag controls. Drag-and-drop is mouse/touch; if the tool will be reused, add arrow-key reordering on top of the example above.
- Do not rely on hover-only controls. Visible click/tap/keyboard controls must carry the workflow.
- Check the tool at 360px wide; avoid fixed heights and side-by-side controls that clip on mobile.
- If color encodes state, include visible labels or a legend; color alone is not enough.
- Add visible focus styles and `aria-label` text for icon-only or visually compact controls.
- Respect `prefers-reduced-motion` if the tool uses animation, transition-heavy reordering, or auto-scroll.
- No tracking, no telemetry.
