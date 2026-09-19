# Anthropic Claude Handoff Patterns

Source snapshot: refreshed 2026-09-01 via Exa from official Anthropic docs,
after the Claude Fable 5.1 release.

- [Models overview](https://platform.claude.com/docs/en/about-claude/models/overview)
- [Prompting Claude Fable 5.1](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-1)
- [Prompting Claude Opus 5](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5)
- [Prompting Claude Fable 5 and Mythos 5](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5)
- [Prompting Claude Sonnet 5](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-sonnet-5)
- [Effort](https://platform.claude.com/docs/en/build-with-claude/effort)
- [Migration guide](https://platform.claude.com/docs/en/about-claude/models/migration-guide)
- [Prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)
- [The new rules of context engineering for Claude 5 generation models](https://claude.com/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models)

## Current lineup

| Model | ID | Best handoff shape |
| --- | --- | --- |
| Claude Fable 5.1 | `claude-fable-5-1` | Newest frontier model; replaces Fable 5 for the hardest ambiguous work. Gains are largest at `xhigh`/`max`; `medium` ≈ Fable 5 at lower cost, and `low` competes with Opus/Sonnet lanes on cost per task |
| Claude Opus 5 | `claude-opus-5` | State of the art on software engineering and knowledge work; the default receiver for demanding implementation, review, and long-horizon agents |
| Claude Fable 5 | `claude-fable-5` | Superseded by Fable 5.1; hand off to it only when the caller pins it |
| Claude Mythos 5 | `claude-mythos-5` | Limited-access lane for approved defensive cybersecurity workflows; ahead of Opus 5 on cyber |
| Claude Sonnet 5 | `claude-sonnet-5` | Fast, high-intelligence coding and agentic work |
| Claude Opus 4.8 | `claude-opus-4-8` | Prior Opus generation; use only when the caller pins it |
| Claude Haiku 4.5 | `claude-haiku-4-5-20251001` | Fast, bounded, lower-cost tasks |

Haiku 4.5 has no undated ID; the others do. CLI aliases (`opus`, `fable`,
`sonnet`) resolve to the latest model in that family — `fable` now resolves to
Fable 5.1, so pin `claude-fable-5` explicitly if the caller wants the prior
model. Pin the full ID in a durable directive. Do not assume Mythos access.

## Claude-specific prompt shape

- Use XML tags or equally clear labeled blocks to separate instructions,
  context, examples, and variable inputs.
- For large context, put source documents first and the task after them. Ask
  Claude to ground conclusions in the supplied sources.
- Explain why an unusual constraint matters when that context changes the
  model's choices.
- Keep runtime controls out of the prompt body. Model, effort, and thinking are
  harness or CLI flags, not prompt text.

## Opus 5

The strongest generally available coding and agentic model. It performs well on
prompts written for Opus 4.8; the deltas below are where carried-over prompts
actively hurt.

- Give the complete task specification up front and let it run. It completes
  whole tasks rather than leaving stubs, and long-horizon work is its strength.
- Start at `xhigh` effort for coding and agentic work; `high` for other
  intelligence-sensitive work; `max` when capability matters more than spend.
  `low` and `medium` are much stronger than on earlier Opus models — use them
  as the primary cost and latency control for bounded slices. Re-sweep effort
  rather than inheriting a value tuned for a prior model.
- Delete verification scaffolding. Opus 5 verifies its own work unprompted, so
  "double-check your answer", "re-verify before responding", or "use a subagent
  to verify" compound with that behavior and burn tokens without improving
  results. Exact required commands are a completion contract, not a nudge — keep
  those.
- Constrain scope for narrow tasks. It will otherwise expand a task with steps
  that were not requested.
- Cap delegation explicitly when the receiver has subagents. It delegates
  readily; say which scenarios justify it and forbid subagents for
  double-checking its own work.
- For review handoffs, ask for everything and filter in a separate pass.
  "Only report high-severity issues" or "be conservative" is followed literally
  and suppresses real findings. Precision and recall both stay high at lower
  effort, so a cheap first pass is viable.
- Prompt explicitly for length. Effort controls thinking volume, not visible
  response length, and both chat responses and written deliverables run longer
  than on prior models.
- Limit correction narration to corrections that change the reader's decisions.

## Fable 5.1 (also covers Fable 5 and Mythos 5)

Fable 5.1 replaces Fable 5. A Fable 5 prompt is a working baseline, but several
carried-over lines now overshoot; bullets that mention 5.1 describe where a
handoff should differ from a Fable 5 prompt, including what to delete. Bullets
without a 5.1 note apply unchanged to the whole family.

- Give the hard, end-to-end outcome and reduce legacy prescription. A brief
  steering instruction often outperforms an enumerated behavior list.
- Include intent: who needs the result and what it enables.
- Effort: start at `high` (the default); use `xhigh`/`max` for
  capability-critical work. 5.1: re-sweep rather than inheriting a Fable 5
  value — effort names do not map to the same thinking across models, `medium`
  roughly matches Fable 5 at lower cost, and `low` is competitive with
  Opus/Sonnet lanes. Preserve an explicit caller setting.
- 5.1 is quieter during long tool-calling turns. When a human watches the run,
  say when user-facing updates are wanted and what each contains (a line before
  starting, brief updates while working, a standalone closing recap). Delete
  carried-over lines like "hold all findings for the final response" — they
  compound with the quieter default.
- For autonomous runs, include a finish-the-whole-task nudge: the user is not
  watching, proceed on reversible actions the request already covers, do not
  end the turn on a plan or promise of work, stop only for destructive actions
  or genuine scope changes. Without it, 5.1 sometimes narrates the next step
  instead of doing it or asks permission for work already requested.
- State what to leave out. 5.1 may fix nearby code or add unrequested tests;
  an explicit rule — report pre-existing bugs as follow-ups instead of fixing
  them, commit tests only where the task asks and sized like neighboring test
  files — removes the extras with no loss in task success.
- For small changes, add: surgically edit files rather than rewriting them when
  the result is identical. 5.1 rewrites whole files more readily than Fable 5.
- At `low` effort, 5.1 searches less and answers from memory more. For
  currency-sensitive work, instruct it to search unrecognized or fast-moving
  names as the user wrote them instead of trusting familiarity — or raise
  effort for those turns.
- Prose deliverables: 5.1 writes denser prose than Fable 5. "Please remove all
  mannered prose" is an effective one-line fix; specify paragraphing when the
  format matters. In chat it also under-formats relative to older models, so
  delete anti-formatting rules carried from earlier prompts.
- Source summaries: 5.1 reproduces source wording without marking quotations
  more than Fable 5. Require marked quotes; one complete worked example in the
  prompt is the reliable fix.
- Long deliverables: prefer `high` effort. At `xhigh`/`max`, 5.1 may draft the
  deliverable in thinking and again in the reply; leave max-output-token
  headroom for both and add a note to use reasoning space to reason and output
  space to write.
- State action boundaries: assessment versus implementation, reversible local
  actions versus destructive/external actions, and the real pause conditions.
- For persistent work, name the memory or lesson location and what is worth
  recording; do not ask it to duplicate repo or chat state.

Fable uses safety classifiers for offensive cybersecurity, biology/life
sciences, and reasoning extraction; 5.1's classifiers produce fewer false
positives than Fable 5's did at that model's launch. Finding vulnerabilities
in source code is permitted.
Benign work may still trigger — phrase compile checks as "are there any bugs in
this program?" rather than "does this compile?", give context for lesser-known
languages, and keep base64 blobs out of tool output. Route to Opus 5 on
repeated refusals. Mythos is limited-access, intended for approved defensive
cybersecurity workflows, and remains ahead of Opus 5 on cyber tasks; preserve
the caller's access and policy boundary rather than inferring one.

## Sonnet 5

- `high` is the default and fits most work; use `xhigh` for the hardest coding
  and agentic tasks. Preserve caller-selected `max`, `medium`, or `low`.
- Adaptive thinking is on by default. Raise effort before adding elaborate
  "think harder" scaffolding.
- It follows instructions literally, especially at lower effort. State the
  intended scope of formatting, transformations, or repeated operations.
- Use explicit visual direction instead of generic negative design prompts.

## Opus 4.8

Prior generation; hand off to it only when the caller pins it. It is literal,
needs `xhigh` for coding, spawns fewer subagents than Opus 5, and unlike Opus 5
it benefits from explicit self-check instructions.

## Haiku 4.5

Give one bounded task, the relevant inputs, an exact output schema, and a short
verification rule. Do not compensate for model fit with a long process prompt.

## Runtime controls

- Keep model IDs, effort, thinking, and output-token controls in the harness.
- Thinking is on by default on Opus 5 and Sonnet 5, and always on for
  Fable/Mythos. On Opus 5 it can be disabled only at effort `high` or below;
  `xhigh` or `max` with thinking disabled is a 400 error. Prefer lower effort
  over disabling thinking.
- At `xhigh` or `max`, give the receiver room to think and act: start around
  64k max output tokens and tune.
- `budget_tokens` is rejected on current models. Control depth with effort.
- Fable 5.1 binds thinking blocks to their exact conversation: histories must
  stay append-only, and per-turn reminders belong in turn-scoped system
  messages. This is a harness/API concern — keep it out of the prompt body,
  but flag it when the receiver is a custom API loop rather than a CLI.
- For custom agent loops on 5.1: a per-turn nudge to batch independent tool
  calls saves round trips, subagent tools should return immediately so the
  lead keeps working, and dense-image work benefits from a crop/zoom tool.
- Query the Models API or current CLI help when exact capabilities matter.

## Good shape

```xml
<context>
[Why the work matters; verified current state; relevant files and evidence]
</context>

<task>
[One explicit outcome with observable success criteria]
</task>

<tool_use>
[Required tools, evidence rules, and delegation limits]
</tool_use>

<constraints>
[Scope, authority, side-effect boundaries, and stop conditions]
</constraints>

<verification>
[Checks to run and evidence required before claiming completion]
</verification>

<output>
[Exact deliverable or report shape]
</output>
```

## Avoid

Four Claude-specific traps that read as good prompting but are not:

- self-check, re-verify, and double-check instructions aimed at Opus 5 — it
  already does this, and the instruction compounds into over-verification;
- conservative-reporting instructions in an Opus 5 review handoff — "only
  high-severity" is obeyed literally and hides real findings;
- asking Fable/Mythos to show, echo, transcribe, or explain private reasoning;
- anti-formatting and narration-suppression rules carried from older models
  into a Fable 5.1 handoff — 5.1 already under-formats and under-narrates, so
  these lines overshoot instead of correcting.
