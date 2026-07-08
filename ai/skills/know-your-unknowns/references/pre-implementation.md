# Pre-implementation techniques

Before any code is written is the cheapest place to find an unknown. Ask for a
blindspot pass when the territory is unfamiliar, brainstorm and prototype when the
user will only know it when they see it, interview them about the rest, and take
references when words run out.

## 1. Blindspot pass

**When:** The user (or you) is about to modify a module neither of you knows well.
Cues: "I've never touched the auth code", "I know nothing about this part",
or you notice the request casually assumes a subsystem is simple.

**Procedure:**
1. Scan the actual module: entry points, callers, invariants, error paths, adjacent
   config, and git history for reverted or contested changes.
2. Report each blindspot as a card: a declarative title naming the risk, the hidden
   behavior, **why it bites** (a concrete failure narrative — "silently fails in
   prod", "account-takeover bug"), and the constraint to add to the prompt.
3. Contrast the naive estimate against actual complexity ("this looks like a two-day
   task; here's why it isn't").
4. Assemble every constraint into one improved implementation prompt the user can
   run next.

**Prompt pattern:** "I'm working on [task] but I know nothing about [module] in this
codebase. Do a blindspot pass: what are my unknown unknowns before I start?"

**Output must contain:** blindspot cards citing real code paths → per-card prompt
fixes → one combined improved prompt.

## 2. Teach me my unknowns

**When:** The task lives in a domain the user lacks vocabulary for (color grading,
audio mastering, typography, cryptography...). Without vocabulary they can't even
phrase the request, let alone evaluate the result.

**Procedure:** Build an interactive HTML explainer (via html-artifacts) with:
1. The domain's mental model (e.g., ingest → correct → grade → match).
2. A **vocabulary ladder**: 5–8 key terms, each with a definition and an example of
   how a professional would phrase a request using it.
3. A live demo where sliders/toggles let the user *feel* what each term changes.
4. A quality checklist — what good output looks like in this domain.
5. High-impact example prompts the user can now articulate.

**Prompt pattern:** "I don't know what [domain] is but I need to [task]. Teach me
[domain] well enough that I understand my unknown unknowns and can prompt you with
real vocabulary."

**Output must contain:** mental model → vocabulary ladder with professional
phrasing → interactive demo → quality checklist → example prompts the user can
now write.

## 3. Design directions (brainstorm what it could look like)

**When:** Greenfield UI and the user has no visual direction — "no taste", "not sure
how it should look", "show me what's possible". Their preferences exist but are
unknown knowns: they can't describe them, but they'll recognize them instantly.

**Procedure:** One HTML page, 3–4 **wildly different** design directions rendering
the *same real data*. Different philosophies, not different accent colors — e.g.,
dense ops console vs. airy editorial cards vs. kanban/timeline hybrid vs. brutalist
mono terminal. Under each direction, toggleable **steal / skip** chips on individual
elements; selections assemble into a formatted reply at the page bottom. The user's
condensed feedback (one winning direction + two or three stolen details) replaces
a design brief.

**Prompt pattern:** "I want a [interface] for [project] but I have no visual taste
and don't know what's possible. Make one HTML page with 4 wildly different design
directions so I can react to them."

**Output must contain:** one page, 3–4 same-data directions with distinct
philosophies → per-element steal/skip chips → assembled copyable reply.

## 4. Mock before you wire

**When:** The interaction design has open questions and nothing is integrated yet.
The user will find out what they actually want the moment they can click it — not
three PRs later.

**Procedure:** A single clickable HTML mock with fake data and zero codebase
integration. Where placement/density/behavior is genuinely uncertain, render the
competing options side by side and attach explicit **A/B questions** (placement,
density, overlay behavior, v1 scope) the user answers by tapping. Answers assemble
into structured feedback.

**Prompt pattern:** "Before wiring anything up, make a single HTML file mocking
[component] with fake data. Include the layout options you're unsure about as
clickable A/B choices."

**Output must contain:** clickable mock with fake data, zero integration →
competing options rendered side by side → tappable A/B questions → assembled
structured feedback.

## 5. Brainstorm the intervention

**When:** The problem is real but fuzzy ("users churn after onboarding") and nobody
has enumerated the solution space. The user can't pick an intervention they don't
know exists.

**Procedure:**
1. Search the actual codebase first — the highest-leverage findings are usually
   machinery that already exists but is disconnected.
2. Produce ~10 interventions sorted cheapest → most ambitious, each tagged with cost
   (S: ship this afternoon → XL: quarter-long bet) and type (wire existing pieces /
   new UI / new hook / new surface), each grounded in named files and code paths.
3. Attach a "this resonates" checkbox per intervention; selections aggregate into a
   copyable reply.

**Prompt pattern:** "Here's my rough problem: [problem]. Search the codebase and
brainstorm 10 places we could intervene, cheapest to most ambitious. I'll tell you
which ones resonate."

**Output must contain:** ~10 interventions tagged with cost and type, each citing
real files → "this resonates" checkboxes → aggregated copyable reply.

## 6. The interview

**When:** The spec is ambiguous and guessing would bake in defaults. Cues: a feature
request that leaves data model, format, scope, or audience open; any request where
two reasonable engineers would build different things.

**Procedure:**
1. List every open question, then order by **architectural blast radius** — ask
   first the questions whose answers would change the data model, type interfaces,
   or system boundaries; cosmetic questions last (or answer them yourself).
2. Ask **one question at a time**. Each question offers concrete options with
   tradeoffs, not an open-ended "what do you want?".
3. Stop when remaining questions no longer change the architecture — don't drain
   the user on trivia.
4. Hand back a **decisions table** (question → answer → consequence) and a
   ready-to-paste implementation prompt encoding every decision.

**Prompt pattern:** "Interview me one question at a time about anything still
ambiguous in [feature]. Prioritize questions where my answer would change the
architecture."

**Output must contain:** questions asked one at a time, ordered by blast radius →
decisions table (question → answer → consequence) → ready-to-paste implementation
prompt encoding every decision.

## 7. Point at a reference

**When:** A working implementation of the desired behavior exists (a crate, another
app, a competitor's flow). Source code is the best reference — words run out before
code does. The risk is misreading it, so require proof of understanding before the
port.

**Procedure:** Read the reference, then produce a **semantics map** for sign-off
*before* writing the port:
1. Behavioral summary per module.
2. Side-by-side code pairs (reference ↔ target language) with numbered callouts on
   semantic traps — integer truncation, inclusive ranges, locking conventions.
3. A behaviors table: preserved exactly / deliberately changed / dropped, each with
   justification.
4. An edge-case table (clock skew, exhaustion, bursts) showing both sides agree.
5. Test vectors lifted verbatim from the reference's test suite.
6. An explicit sign-off gate: implementation starts only after the user confirms
   the map.

**Prompt pattern:** "[Reference] implements the exact behavior I want. Read it and
reimplement the same semantics in [target] — but first show me a semantics map so I
can confirm you understood it."

**Output must contain:** behavioral summary → side-by-side code pairs with trap
callouts → preserved/changed/dropped table → edge-case table → test vectors →
explicit sign-off gate before any port is written.

## 8. The tweakable plan

**When:** Any implementation plan. Traditional plans are ordered by build sequence,
which buries the decisions the user actually has opinions about under mechanical
plumbing they'd rubber-stamp anyway.

**Procedure:** Structure by **likelihood of revision**, not execution order:
- **Section A — decisions you'll want to tweak:** data model choices, new type
  interfaces, anything user-facing. Flag each choice with the plan's pick *and* the
  considered alternatives, plus a one-line "switch to X" revision the user can send
  back. Attach effort estimates so the cost of each revision path is visible.
- **Section B — execution order:** the actual build sequence.
- **Section C — mechanical work, collapsed:** renames, fixtures, migrations, marked
  "no judgment calls here — safe to skip".

End with a "tweak these three things" footer: the three highest-leverage decisions
awaiting reaction.

**Prompt pattern:** "Write an implementation plan for [feature], but lead with the
decisions I'm most likely to tweak — data model changes, new type interfaces,
anything user-facing. Bury the mechanical refactoring at the bottom."

**Output must contain:** Section A decisions (pick + alternatives + effort + a
one-line "switch to X") → Section B build order → Section C collapsed mechanical
work marked skippable → "tweak these three things" footer.
