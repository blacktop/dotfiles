---
name: draw-the-owl
description: >-
  Decompose large agent-built features into atomic, reviewable chunks using a
  diff-size budget (~1500 lines) as the signal. Use this whenever implementing
  a non-trivial or net-new feature with an agent, when an agent has produced a
  huge diff/PR that is painful to review, when the user says a change is "too
  big", "too much to review", or "should be broken up", or when planning how to
  parallelize feature work across multiple agents. Reach for it on any "build
  this whole feature" request, even when the user does not explicitly ask to
  decompose — getting under the review-ability threshold is the goal. Skip it
  for small, self-contained features that will obviously land well under the
  threshold, and for large-but-mechanical sweeps (renames, codemods, lockfile
  churn) where the diff is big but trivially reviewable.
version: 1.0.0
---

# Draw the Owl

A pattern for building features with agents, from Mitchell Hashimoto. The core
insight: **the binding constraint on agent feature work is not whether the code
runs, it's whether a human can review it.** A diff you cannot review is a diff
you cannot trust, no matter how green the tests are. So the loop optimizes for
shrinking changes below your review-ability threshold rather than for getting a
working feature in one shot.

The name is the "draw the owl" meme — *step 1: draw two circles; step 2: draw
the rest of the owl.* The first prompt is deliberately that underspecified: ask
for the whole feature, loosely guided, and expect garbage. The garbage is not
the deliverable. It is reconnaissance — it reveals the true shape of the
problem so you can carve it into pieces worth reviewing.

## When to Use

- Implementing a non-trivial or net-new feature with an agent.
- An agent produced a diff that is hard to review with confidence — usually
  because it is large (very roughly >1500 reviewable lines), but judge the
  review effort, not the raw line count.
- The user calls a change "too big", "too much to review", or asks to "break
  this up" / "split this into smaller PRs".
- Planning how to spread feature work across several agents in parallel.
- Any "just build the whole thing" request where you want a maintainable,
  reviewable result rather than one giant unreviewable commit.

## When NOT to Use

- Small, self-contained changes that will obviously land well under the
  threshold — a bug fix, a refactor of one module, a config tweak. Decomposing
  these is pure overhead.
- Mechanical, uniform sweeps (rename, codemod, dependency bump) where the diff
  is large but trivially reviewable because every hunk is the same shape. Size
  is a proxy for review effort, not the target itself.
- Pure exploration or research where no code is being merged.
- Work that is already a clean stream of small commits — you are past the
  problem this solves.

## The Loop

### 1. Draw the owl

Prompt the agent to implement the whole feature, loosely guided. Do not
over-specify; the point is to see what the agent reaches for and what the
change actually touches. Expect the result to be wrong, sprawling, or both.
That is the expected outcome, not a failure — you are buying information about
the problem's shape, not a mergeable change.

### 2. Measure against the budget

Look at the diff size.

- **Under ~1500 lines:** review it and iterate normally. You are below the
  review-ability threshold; the owl is good enough to refine in place. Stop
  here — do not decompose for its own sake.
- **Over ~1500 lines:** the change is too big to review well. Do not try to
  review it anyway. Decompose (step 3).

The 1500-line number is a heuristic, not a law — a proxy for "more than I can
hold in my head in one review pass." Adjust it to the codebase and to your own
review stamina: dense, invariant-heavy core code warrants a smaller budget;
boilerplate-heavy or well-tested surface area can tolerate more. What matters
is having *a* threshold and respecting it, because the failure mode it guards
against is rubber-stamping a diff you didn't actually understand.

Discount trivially-reviewable bulk (generated files, lockfiles, mass renames)
when sizing — those lines don't cost review effort. Size is standing in for
*review effort*; judge the effort, not the raw count.

### 3. Decompose into atomic tasks — and generalize them

Ask the agent to break the problem into atomic, incremental, independently
reviewable tasks. **Do this yourself in parallel** and compare — the agent's
decomposition and yours will disagree in informative ways.

The critical, human-shaped step: **agents over-fit the decomposition to the
specific solution they just produced.** They will hand you tasks shaped like
"extract the `parseFooBarResponse` helper I happened to write" rather than the
general, durable seams the feature actually has. Massage the task list back
into the right general shape — the boundaries that would exist regardless of
how this particular owl got drawn. This is where your architectural judgment
earns its keep; it is the part the agent cannot reliably do, because it only
has its own first attempt to reason from.

Good seams are usually: data model / schema changes, then the layer that
consumes them, then the UI/API surface, then wiring and tests — each landing
as a change small enough to review on its own and ideally mergeable
independently.

Throw away the owl's code at this point if it is garbage. Its job was to teach
you the decomposition; the pieces get built fresh.

### 4. Dispatch the pieces, recursively

Kick off new agents on the incremental tasks, parallelized as far as the
dependency graph allows. Each piece is itself subject to the same rule: if a
sub-task's diff blows past the budget, decompose *it* too. The loop is
recursive — you keep splitting until every landing change is reviewable.

For running several agents at once, this is exactly the
[`tmux-pm`](../tmux-pm/SKILL.md) pattern: one PM session dispatching bounded
workers in isolated worktrees, each on one atomic task, reporting back for
review and merge. For handing a single decomposed task to a fresh agent with
clean context, use the [`handoff`](../handoff/SKILL.md) skill to write the task
prompt. Frontier models at high/xhigh effort run slowly enough that you can
keep several pieces in flight while actively reviewing others or doing your own
work — the latency is a feature, not a cost, because it matches the cadence of
human review.

### 5. Re-draw the owl

Periodically re-run the "draw the owl" prompt on what remains. As the
decomposed pieces land, the remaining feature shrinks; at some point a fresh
whole-feature attempt comes back *under* the review-ability threshold and you
are done — the last owl is just mergeable. This is the convergence condition:
keep drawing owls and carving until one fits.

One floor case: some features have an irreducible core that is itself over
budget — a single dense state machine, a protocol codec — where no seam splits
it smaller. When the smallest honest seam still exceeds the threshold, stop
recursing. Shrink the per-pass budget instead and review that core slowly and
deliberately, ideally pairing on it; decomposition has done all it can and the
remaining cost is real review attention, not more splitting.

## Keep the human in the loop

This pattern is deliberately human-in-the-loop, and feature work is exactly
where that matters most. Features touch human boundaries — UI, API shape,
naming, product behavior — that no test fully pins down, and net-new code can
introduce architectural pathologies that violate invariants you never wrote
down. The review threshold exists so a human actually sees those boundary
decisions before they calcify. Encode the invariants you *can* into specs and
tests so future passes catch them mechanically, but assume the spec is
incomplete and review the seams yourself.

Continuous agents-driving-agents loops have their place, but for daily
get-it-done feature work, the reviewable-chunk loop above is the higher-yield
pattern: every piece lands ready to merge as-is or with light human refinement.

## Checklist

- [ ] First attempt was a loose "draw the owl" prompt, not an over-specified one.
- [ ] Diff measured against a review-effort budget (~1500 lines, adjusted) —
      generated/lockfile/rename lines subtracted before comparing.
- [ ] If over budget: decomposed by both the agent and you, then reconciled.
- [ ] Agent-proposed tasks generalized away from the throwaway solution's shape.
- [ ] Pieces dispatched (parallel where possible), each re-checked against the
      budget and split further if needed.
- [ ] Owl re-drawn as pieces land, until the remainder is reviewable.
- [ ] Human reviewed the human-boundary seams (UI/API/naming/invariants).

## See Also

- [`tmux-pm`](../tmux-pm/SKILL.md) — orchestrate the parallel worker agents that
  build the decomposed pieces.
- [`handoff`](../handoff/SKILL.md) — write the fresh-context task prompt for each
  decomposed piece handed to another agent.
